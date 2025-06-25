require 'open-uri'
require 'marcel'

class FireflyController < ApplicationController
  @aws_service = PresignedUrlService.new

    def self.aws_service
      @aws_service
    end

    def bearer_token
      unless session[:bearer_token]
        session[:client_id] = ENV['ADOBE_CLIENT_ID']
        client_secret = ENV['ADOBE_CLIENT_SECRET']
    
        begin
          response = RestClient.post('https://ims-na1.adobelogin.com/ims/token/v3', {
            client_id: session[:client_id],
            client_secret: client_secret,
            grant_type: 'client_credentials',
            scope: 'openid, AdobeID, read_organizations, firefly_api, ff_apis, creative_sdk'
          })
          json_response = JSON.parse(response.body)
          session[:bearer_token] = json_response['access_token']
        rescue RestClient::ExceptionWithResponse => e
          render json: { error: 'Unable to fetch token', details: e.response }, status: :unauthorized and return
        end
      end
      session[:bearer_token]
    end
  
    # Uploads an image to AWS
    def upload_image    
        image_file = params[:image_file]
        urls = generate_input_urls
  
        begin
          self.class.aws_service.upload_to_presigned_url(urls[:input][:put_url], image_file)

          render json: { input_url: urls[:input][:get_url]}
        rescue => e
            render json: { error: e.message }, status: :internal_server_error
        end
    end

      def generate_custom_model_image
        uri = URI.parse("https://firefly-api.adobe.io/v3/images/generate-async")
      
        body = {
          "prompt" => params[:prompt],
          "contentClass" => "photo",
          "customModelId" => "urn:aaid:sc:VA6C2:baf71dd5-653c-448a-bbed-b8b80aaf2220",
        }.to_json
      
        initial_response = call_api(uri, body)
      
        unless initial_response.is_a?(Net::HTTPSuccess)
          render json: { error: initial_response.body }, status: :unprocessable_entity
          return
        end
      
        # Parse job ID from the response
        json_response = JSON.parse(initial_response.body)
        job_id = json_response["jobId"]
      
        unless job_id
          render json: { error: 'Could not extract job_id' }, status: :unprocessable_entity
          return
        end
      
        # Wait for the job to complete
        status = wait_for_firefly_job(job_id)
      
        if status["status"].to_s.downcase == "succeeded"
          image_url = status.dig("result", "outputs", 0, "image", "url")
      
          if image_url
            render json: {
              message: 'Image generation succeeded',
              image_url: image_url,
              job_id: job_id
            }
          else
            render json: { error: "Job succeeded but no image URL found." }, status: :unprocessable_entity
          end
        else
          render json: {
            message: 'Job did not complete in time or failed',
            job_id: job_id,
            last_status: status
          }, status: :request_timeout
        end
      end

      # Expands the background of an image using Firefly's Expand API
      def expand_image
        # Setup the HTTP request
        uri = URI.parse('https://firefly-api.adobe.io/v3/images/expand-async')
        urls = generate_input_urls
        new_input_url = urls[:input][:get_url]
        new_input_put_url = urls[:input][:put_url]

        original_url = params[:input_url]
        download = OpenURI.open_uri(original_url)
        tempfile = Tempfile.new(['input', '.jpg'])
        tempfile.binmode
        tempfile.write(download.read)
        tempfile.rewind

        content_type = Marcel::MimeType.for(tempfile) || "image/jpeg"

        # Create a fake uploaded file-like object
        uploaded_file = ActionDispatch::Http::UploadedFile.new(
          tempfile: tempfile,
          filename: "input.jpg",
          type: content_type
        )
        
        self.class.aws_service.upload_to_presigned_url(urls[:input][:put_url], uploaded_file)

      
        body = {
          size: { width: params[:width], height: params[:height] },
          image: { source: { url: new_input_url }, type: content_type, }
      }.to_json
      
        response = call_api(uri, body)
      
        job_id = response["jobId"]
      
        unless job_id
          render json: { error: 'Could not extract job_id' }, status: :unprocessable_entity
          return
        end
      
        # Wait for the job to complete
        status = wait_for_firefly_job(job_id)
      
        if status["status"].to_s.downcase == "succeeded"
          image_url = status.dig("result", "outputs", 0, "image", "url")
      
          if image_url
            render json: {
              message: 'Image generation succeeded',
              image_url: image_url,
              job_id: job_id
            }
          else
            render json: { error: "Job succeeded but no image URL found." }, status: :unprocessable_entity
          end
        else
          render json: {
            message: 'Job did not complete in time or failed',
            job_id: job_id,
            last_status: status
          }, status: :request_timeout
        end
      end

      def fill_image
        uri = URI.parse('https://firefly-api.adobe.io/v3/images/fill-async')
        input_url = params[:input_url]
        mask_url = params[:mask_url]

        if input_url.blank? || mask_url.blank?
          render json: { error: "Missing input_url or mask_url" }, status: :bad_request and return
        end
        
        input_urls = generate_input_urls
      
        input_get_url = input_urls[:input][:get_url]
        input_put_url = input_urls[:input][:put_url]
      
        # Download and re-upload the original image
        input_download = URI.open(input_url)
        input_tempfile = Tempfile.new(['input', '.jpg'])
        input_tempfile.binmode
        input_tempfile.write(input_download.read)
        input_tempfile.rewind
      
        input_content_type = Marcel::MimeType.for(input_tempfile) || "image/jpeg"
        input_uploaded_file = ActionDispatch::Http::UploadedFile.new(
          tempfile: input_tempfile,
          filename: "input.jpg",
          type: input_content_type
        )
        self.class.aws_service.upload_to_presigned_url(input_put_url, input_uploaded_file)
      
        body = {
          image: {
            source: {
              url: input_get_url
            },
          },
          mask: {
            invert: false,
            source: {
              url: params[:mask_url]
            }
          },
          prompt: params[:prompt]
        }.to_json
      
        response = call_api(uri, body)
        job_id = response["jobId"]
      
        unless job_id
          render json: { error: 'Could not extract job_id' }, status: :unprocessable_entity
          return
        end
      
        status = wait_for_firefly_job(job_id)
      
        if status["status"].to_s.downcase == "succeeded"
          image_url = status.dig("result", "outputs", 0, "image", "url")
          if image_url
            render json: {
              message: 'Image fill succeeded',
              image_url: image_url,
              job_id: job_id
            }
          else
            render json: { error: "Job succeeded but no image URL found." }, status: :unprocessable_entity
          end
        else
          render json: {
            message: 'Job did not complete in time or failed',
            job_id: job_id,
            last_status: status
          }, status: :request_timeout
        end
      end

      private

      def call_api(uri, body)
        url = URI.parse(uri)
        http = Net::HTTP.new(url.host, url.port)
        http.use_ssl = true
    
        req = Net::HTTP::Post.new(url.path)
        req['Authorization'] = "Bearer #{bearer_token}"
        req['x-api-key'] = session[:client_id]
        req['Accept'] = "application/json"
        req['Content-Type'] = "application/json"
        req.body = body
    
        response = http.request(req)
        response_json = JSON.parse(response.body)

        if response_json["error_code"] == "401013"
          session[:bearer_token] = nil
          redirect_to root_path, alert: "Session expired. Please sign in again."
        else
          response_json
        end
      end

      def wait_for_firefly_job(job_id)
        max_retries = 3600
        retries = 0
      
        loop do
          status_response = get_status(job_id)
          current_status = status_response['status']&.downcase
      
          Rails.logger.info("[Firefly] Job #{job_id} status: #{current_status || 'unknown'}, retry #{retries}/#{max_retries}")
      
          return status_response if current_status == 'succeeded' || current_status == 'failed' || retries >= max_retries
      
          sleep 2
          retries += 1
        end
      end

      def get_status(job_id)
        url = URI.parse("https://firefly-api.adobe.io/v3/status/#{job_id}")
        http = Net::HTTP.new(url.host, url.port)
        http.use_ssl = true
      
        req = Net::HTTP::Get.new(url.request_uri) 
        req['Authorization'] = "Bearer #{bearer_token}"
        req['x-api-key'] = session[:client_id]
        req['Content-Type'] = 'application/json'
      
        response = http.request(req)
        JSON.parse(response.body)
      end

      def generate_input_urls
        aws = self.class.aws_service
      
        uuid = SecureRandom.uuid
        input_key = "inputs/#{uuid}.jpg"
      
        {
          input: {
            key: input_key,
            put_url: aws.generate_put_url(input_key, expires_in: 86400),
            get_url: aws.generate_get_url(input_key, expires_in: 86400)
          }
        }
      end
  end