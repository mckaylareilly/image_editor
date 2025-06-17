class PhotoshopController < ApplicationController
    before_action :get_token
    before_action :set_aws_service
  
    def get_token
      @client_id = ENV['ADOBE_CLIENT_ID']
      client_secret = ENV['ADOBE_CLIENT_SECRET']
  
      begin
        response = RestClient.post('https://ims-na1.adobelogin.com/ims/token/v3', {
          client_id: @client_id,
          client_secret: client_secret,
          grant_type: 'client_credentials',
          scope: 'openid, AdobeID, read_organizations, firefly_api, ff_apis, creative_sdk'
        })
  
        json_response = JSON.parse(response.body)
        @bearer_token = json_response['access_token']
      rescue RestClient::ExceptionWithResponse => e
        render json: { error: 'Unable to fetch token', details: e.response }, status: :unauthorized
      end
    end

    def set_aws_service
      @aws_service = PresignedUrlService.new
    end
  
    def perform_action_json
      input_file = params[:input_file]
  
      if input_file.blank?
        render json: { error: 'Missing input or actions file' }, status: :bad_request
        return
      end
  
      begin
        urls = generate_action_json_urls
  
        @aws_service.upload_to_presigned_url(urls[:input][:put_url], input_file)
        
        url = 'https://image.adobe.io/pie/psdService/actionJSON'
        body = {
          inputs: [{ href: urls[:input][:get_url], storage: "external" }],
          "options": {
    "actionJSON": [{
        "_obj": "imageSize",
        "constrainProportions": true,
        "interfaceIconFrameDimmed": {
          "_enum": "interpolationType",
          "_value": "automaticInterpolation"
        },
        "scaleStyles": true
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
        
        status = wait_for_photoshop_job(job_id)
  
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
      input_file = params[:input_file]
      actions_file = params[:actions_file]
  
      if input_file.blank? || actions_file.blank?
        render json: { error: 'Missing input or actions file' }, status: :bad_request
        return
      end
  
      begin
        urls = generate_input_output_urls
  
        @aws_service.upload_to_presigned_url(urls[:input][:put_url], input_file)
        @aws_service.upload_to_presigned_url(urls[:action][:put_url], actions_file)
        
        url = 'https://image.adobe.io/pie/psdService/photoshopActions'
        body = {
          inputs: [{ href: urls[:input][:get_url], storage: "external" }],
          options: { actions: [{ href: urls[:action][:get_url], storage: "external" }] },
          outputs: [{ href: urls[:output][:put_url], storage: "external", type: "image/jpeg" }]
        }.to_json

        adobe_response = call_api(url, body)
  
        job_href = adobe_response.dig('_links', 'self', 'href')
        job_id = job_href&.split('/')&.last
  
        unless job_id
          render json: { error: 'Could not extract job_id' }, status: :unprocessable_entity
          return
        end
        
        status = wait_for_photoshop_job(job_id)
  
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
      input_file = params[:input_file]
  
      if input_file.blank?
        render json: { error: 'Missing input or actions file' }, status: :bad_request
        return
      end
  
      begin
        urls = generate_input_output_urls
  
        @aws_service.upload_to_presigned_url(urls[:input][:put_url], input_file)
        
        url = 'https://image.adobe.io/sensei/cutout'
        body = {
          input: {
            href: urls[:input][:get_url],
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
        
        status = wait_for_photoshop_mask_job(job_id)
  
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

    private

    def call_api(uri, body)
      url = URI.parse(uri)
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
  
      req = Net::HTTP::Post.new(url.path)
      req['Authorization'] = "Bearer #{@bearer_token}"
      req['x-api-key'] = @client_id
      req['Content-Type'] = 'application/json'
      req.body = body
  
      response = http.request(req)
      JSON.parse(response.body)
    end

    def generate_action_json_urls
      input_key = @aws_service.generate_key("inputs", "jpg")
      action_key = @aws_service.generate_key("actions", "atn")
      output_key = @aws_service.generate_key("outputs", "jpg")
    
      {
        input: { key: input_key, put_url: @aws_service.generate_put_url(input_key), get_url: @aws_service.generate_get_url(input_key) },
        action: { key: action_key, put_url: @aws_service.generate_put_url(action_key), get_url: @aws_service.generate_get_url(action_key) },
        output: { key: output_key, put_url: @aws_service.generate_put_url(output_key), get_url: @aws_service.generate_get_url(output_key) }
      }
    end

    def generate_input_output_urls
      input_key = @aws_service.generate_key("inputs", "jpg")
      output_key = @aws_service.generate_key("outputs", "jpg")
    
      {
        input: { key: input_key, put_url: @aws_service.generate_put_url(input_key), get_url: @aws_service.generate_get_url(input_key) },
        output: { key: output_key, put_url: @aws_service.generate_put_url(output_key), get_url: @aws_service.generate_get_url(output_key) }
      }
    end
  
    def wait_for_photoshop_job(job_id)
      max_retries = 30
      retries = 0
  
      loop do
        status_response = get_status(job_id)
        current_status = status_response['outputs']&.first&.dig('status')&.downcase
        return status_response if current_status == 'succeeded' || retries >= max_retries
  
        sleep 2
        retries += 1
      end
    end

    def wait_for_photoshop_mask_job(job_id)
      max_retries = 30
      retries = 0
  
      loop do
        status_response = get_mask_status(job_id)
        current_status = status_response['status']&.downcase
        return status_response if current_status == 'succeeded' || retries >= max_retries
  
        sleep 2
        retries += 1
      end
    end

    def get_status(job_id)
      url = URI.parse("https://image.adobe.io/pie/psdService/status/#{job_id}")
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
    
      req = Net::HTTP::Get.new(url.path)
      req['Authorization'] = "Bearer #{@bearer_token}"
      req['x-api-key'] = @client_id
      req['Content-Type'] = 'application/json'
    
      response = http.request(req)
      JSON.parse(response.body)
    end


    def get_mask_status(job_id)
      url = URI.parse("https://image.adobe.io/sensei/status/#{job_id}")
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
    
      req = Net::HTTP::Get.new(url.path)
      req['Authorization'] = "Bearer #{@bearer_token}"
      req['x-api-key'] = @client_id
      req['Content-Type'] = 'application/json'
    
      response = http.request(req)
      JSON.parse(response.body)
    end
  end