require 'mini_magick'

class PhotoshopController < ApplicationController
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
  
    def perform_action_json
      input_url = params[:input_url]
  
      if input_url.blank?
        render json: { error: 'Missing image' }, status: :bad_request
        return
      end
  
      begin
        urls = generate_input_output_urls

        url = 'https://image.adobe.io/pie/psdService/actionJSON'
        body = {
          inputs: [{ href: input_url, storage: "external" }],
          "options": {
            "actionJSON": [{
              "_obj": "invert",
              "_target": [
                {
                  "_ref": "layer",
                  "_enum": "ordinal",
                  "_value": "targetEnum"
                }
            ],
          }, {
            "_obj": "imageSize",
            "constrainProportions": true,
            "interfaceIconFrameDimmed": {
              "_enum": "interpolationType",
              "_value": "automaticInterpolation"
            },
            "resolution": {
              "_unit": "densityUnit",
              "_value": 72.0
            },
            "scaleStyles": true
          },
          {
            "_obj": "make",
            "_target": [{
               "_ref": "adjustmentLayer"
            }],
            "using": {
              "_obj": "adjustmentLayer",
              "type": {
                "_obj": "blackAndWhite",
                "blue": 20,
                "cyan": 60,
                "grain": 40,
                "magenta": 80,
                "presetKind": {
                  "_enum": "presetKindType",
                  "_value": "presetKindDefault"
                },
                "red": 40,
                "tintColor": {
                  "_obj": "RGBColor",
                  "blue": 179.00115966796876,
                  "grain": 211.00067138671876,
                  "red": 225.00045776367188
                },
                "useTint": false,
                "yellow": 60
              }
            }
          }
        ]
      },
      outputs: [{ href: urls[:output][:put_url], storage: "external", type: "image/jpeg" }]
      }.to_json

      adobe_response = call_api(url, body)
  
      job_href = adobe_response.dig('_links', 'self', 'href')
      job_id = job_href&.split('/')&.last
  
      unless job_id
        render json: { error: 'Could not extract job_id' }, status: :unprocessable_entity
        return
      end
        
      status = wait_for_photoshop_job(job_id, urls)
  
      if status.dig("outputs", 0, "status").to_s.downcase == "succeeded"
        render json: {
          message: 'Photoshop action succeeded',
          output_url: urls[:output][:get_url]
        }
      else
        render json: {
          message: 'Job did not complete in time',
          job_id: job_id,
          last_status: status
        }, status: :request_timeout
      end
      rescue => e
        Rails.logger.error "Photoshop perform_actions error: #{e.message}\n#{e.backtrace.join("\n")}"
        render json: { error: 'Server error', details: e.message }, status: :internal_server_error
      end
    end
  
    def perform_actions
      input_url = params[:input_url]
      actions_file = params[:actions_file]
  
      if input_url.blank? || actions_file.blank?
        render json: { error: 'Missing input or actions file' }, status: :bad_request
        return
      end
  
      begin
        urls = generate_input_output_urls
        action_urls = generate_input_urls
  
        self.class.aws_service.upload_to_presigned_url(action_urls[:input][:put_url], actions_file)
        
        url = 'https://image.adobe.io/pie/psdService/photoshopActions'
        body = {
          inputs: [{ href: input_url, storage: "external" }],
          options: { actions: [{ href: action_urls[:input][:get_url], storage: "external" }] },
          outputs: [{ href: urls[:output][:put_url], storage: "external", type: "image/jpeg" }]
        }.to_json

        adobe_response = call_api(url, body)
  
        job_href = adobe_response.dig('_links', 'self', 'href')
        job_id = job_href&.split('/')&.last
  
        unless job_id
          render json: { error: 'Could not extract job_id' }, status: :unprocessable_entity
          return
        end
        
        status = wait_for_photoshop_job(job_id, urls)
  
        if status.dig("outputs", 0, "status").to_s.downcase == "succeeded"
          render json: {
            message: 'Photoshop action succeeded',
            output_url: urls[:output][:get_url]
          }
        else
          render json: {
            message: 'Job did not complete in time',
            job_id: job_id,
            last_status: status
          }, status: :request_timeout
        end
      rescue => e
        Rails.logger.error "Photoshop perform_actions error: #{e.message}\n#{e.backtrace.join("\n")}"
        render json: { error: 'Server error', details: e.message }, status: :internal_server_error
      end
    end

    def remove_background
      input_url = params[:input_url]
  
      if input_url.blank?
        render json: { error: 'Missing image' }, status: :bad_request
        return
      end
  
      begin
        urls = generate_input_output_urls
          
        url = 'https://image.adobe.io/sensei/cutout'
        body = {
          input: {
            href: params[:input_url],
            storage: "external"
          },
          output: {
            href: urls[:output][:put_url],
            storage: "external"
          }
        }.to_json

        adobe_response = call_api(url, body)
  
        job_href = adobe_response.dig('_links', 'self', 'href')
        job_id = job_href&.split('/')&.last
  
        unless job_id
          render json: { error: 'Could not extract job_id' }, status: :unprocessable_entity
          return
        end
        
        status = wait_for_photoshop_mask_job(job_id, urls)
  
        if status['status']&.downcase == "succeeded"
          render json: {
            message: 'Photoshop remove background succeeded',
            output_url: urls[:output][:get_url]
          }
        else
          render json: {
            message: 'Job did not complete in time',
            job_id: job_id,
            last_status: status
          }, status: :request_timeout
        end
      rescue => e
        Rails.logger.error "Photoshop perform_actions error: #{e.message}\n#{e.backtrace.join("\n")}"
        render json: { error: 'Server error', details: e.message }, status: :internal_server_error
      end
    end

    def create_mask
      input_url = params[:input_url]
    
      if input_url.blank?
        render json: { error: 'Missing image' }, status: :bad_request
        return
      end
    
      begin
        urls = generate_input_output_urls
    
        url = 'https://image.adobe.io/sensei/mask'
        body = {
          input: {
            href: input_url,
            storage: "external"
          },
          output: {
            href: urls[:output][:put_url],
            storage: "external"
          }
        }.to_json
    
        adobe_response = call_api(url, body)
    
        job_href = adobe_response.dig('_links', 'self', 'href')
        job_id = job_href&.split('/')&.last
    
        unless job_id
          render json: { error: 'Could not extract job_id' }, status: :unprocessable_entity
          return
        end
    
        status = wait_for_photoshop_mask_job(job_id, urls)
    
        if status['status']&.downcase == "succeeded"
          # Step 1: Download the generated mask image
          downloaded = URI.open(urls[:output][:get_url])
          original_tempfile = Tempfile.new(['mask_original', '.jpg'])
          original_tempfile.binmode
          original_tempfile.write(downloaded.read)
          original_tempfile.rewind
    
          # Step 2: Invert using MiniMagick
          inverted_tempfile = Tempfile.new(['mask_inverted', '.jpg'])
          image = MiniMagick::Image.read(original_tempfile)
          image.negate
          image.write(inverted_tempfile.path)
    
          # Step 3: Upload inverted image to a new presigned URL
          inverted_urls = generate_input_urls
          inverted_get_url = inverted_urls[:input][:get_url]
          inverted_put_url = inverted_urls[:input][:put_url]
    
          content_type = Marcel::MimeType.for(inverted_tempfile) || "image/jpeg"
          inverted_uploaded_file = ActionDispatch::Http::UploadedFile.new(
            tempfile: inverted_tempfile,
            filename: "inverted_mask.jpg",
            type: content_type
          )
          self.class.aws_service.upload_to_presigned_url(inverted_put_url, inverted_uploaded_file)
    
          render json: {
            message: 'Photoshop create mask succeeded',
            output_url: inverted_get_url
          }
        else
          render json: {
            message: 'Job did not complete in time',
            job_id: job_id,
            last_status: status
          }, status: :request_timeout
        end
      rescue => e
        Rails.logger.error "Photoshop perform_actions error: #{e.message}\n#{e.backtrace.join("\n")}"
        render json: { error: 'Server error', details: e.message }, status: :internal_server_error
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
      req['Content-Type'] = 'application/json'
      req.body = body
  
      response = http.request(req)
      response_json = JSON.parse(response.body)

      if response_json["error_code"] == "401013"
        session[:bearer_token] = nil
      else
        response_json
      end
    end

    def generate_input_output_urls
      aws = self.class.aws_service
    
      input_key = uuid = SecureRandom.uuid
      output_key = uuid = SecureRandom.uuid

      input_key = "inputs/#{uuid}.jpg"
      output_key = "outputs/#{uuid}.jpg"
    
      {
        input: {
          key: input_key,
          put_url: aws.generate_put_url(input_key),
          get_url: aws.generate_get_url(input_key)
        },
        output: {
          key: output_key,
          put_url: aws.generate_put_url(output_key),
          get_url: aws.generate_get_url(output_key)
        }
      }
    end

    def generate_input_urls
      aws = self.class.aws_service
    
      input_key = uuid = SecureRandom.uuid

      input_key = "inputs/#{uuid}.jpg"    
      {
        input: {
          key: input_key,
          put_url: aws.generate_put_url(input_key, expires_in: 86400),
          get_url: aws.generate_get_url(input_key, expires_in: 86400)
        }
      }
    end

    def wait_for_photoshop_job(job_id, urls)
      max_retries = 30
      retries = 0
    
      loop do
        status_response = get_status(job_id)
        current_status = status_response.dig("outputs", 0, "status")&.downcase
    
        if current_status == 'succeeded' || retries >= max_retries
          session[:input_url] = urls[:output][:get_url]
          return status_response
        end
    
        sleep 2
        retries += 1
      end
    end
    
    def wait_for_photoshop_mask_job(job_id, urls)
      max_retries = 30
      retries = 0
    
      loop do
        status_response = get_mask_status(job_id)
        current_status = status_response['status']&.downcase
    
        if current_status == 'succeeded' || retries >= max_retries
          session[:input_url] = urls[:output][:get_url]

          return status_response
        end
    
        sleep 2
        retries += 1
      end
    end

    def get_status(job_id)
      url = URI.parse("https://image.adobe.io/pie/psdService/status/#{job_id}")
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
    
      req = Net::HTTP::Get.new(url.path)
      req['Authorization'] = "Bearer #{bearer_token}"
      req['x-api-key'] = session[:client_id]
      req['Content-Type'] = 'application/json'
    
      response = http.request(req)
      JSON.parse(response.body)
    end


    def get_mask_status(job_id)
      url = URI.parse("https://image.adobe.io/sensei/status/#{job_id}")
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
    
      req = Net::HTTP::Get.new(url.path)
      req['Authorization'] = "Bearer #{bearer_token}"
      req['x-api-key'] = session[:client_id]
      req['Content-Type'] = 'application/json'
    
      response = http.request(req)
      JSON.parse(response.body)
    end
  end