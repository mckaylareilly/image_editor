class FireflyController < ApplicationController
    before_action :get_token
  
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
  
    # Uploads an image to Firefly
    def upload_image    
        image_url = params[:imageUrl]
  
        # Fetch the ActiveStorage blob from the URL
        image_uri = URI.parse(image_url)
        signed_id = image_uri.path.split('/')[5]
        
        # Get image from ActiveStorage 
        blob = ActiveStorage::Blob.find_signed(signed_id)
        
        # Open the blob and read it
        file = blob.download
        
        if file.blank?
          render json: { error: 'No image uploaded' }, status: :unprocessable_entity
          return
        end
        
        # Setup the request
        content_type = blob.content_type
        url = URI.parse('https://firefly-api.adobe.io/v2/storage/image')
  
        http = Net::HTTP.new(url.host, url.port)
        http.use_ssl = true  
  
        req = Net::HTTP::Post.new(url.path)
        req['Authorization'] = "Bearer #{@bearer_token}"
        req['x-api-key'] = @client_id
        req['Content-Type'] = content_type
  
        req.body = file
  
        begin
            response = http.request(req)
            result = JSON.parse(response.body)
  
            if response.is_a?(Net::HTTPSuccess)
                render json: { message: 'Image uploaded successfully', image_id: result['images'].first['id'] }
            else
                render json: { error: result }, status: :unprocessable_entity
            end
        rescue => e
            render json: { error: e.message }, status: :internal_server_error
        end
    end
  
    # Generates an image using Firefly's API from a prompt and a reference image
    def generate_image
        # Setup the HTTP request
        uri = URI.parse("https://firefly-api.adobe.io/v3/images/generate")
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
      
        req = Net::HTTP::Post.new(uri.path)
        req["Authorization"] = "Bearer #{@bearer_token}"
        req["x-api-key"] = @client_id
        req["Content-Type"] = "application/json"
      
        permitted_params = params.require(:firefly).permit(:prompt, :firefly_image_id)
      
        firefly_image_id = permitted_params[:firefly_image_id]
        prompt = permitted_params[:prompt]
          
        if firefly_image_id.nil?
          render json: { error: "Firefly image ID is missing. Please upload an image first." }, status: :unprocessable_entity
          return
        end
      
        body = {
          "numVariations" => 1,
          "seeds" => [0],
          "size" => { "width" => 2048, "height" => 2048 },
          "prompt" => prompt, 
          "contentClass" => "photo",
          "visualIntensity" => 2,
          "structure" => {
            "strength" => 100,
            "imageReference" => {
              "source" => { "uploadId" => firefly_image_id }
            }
          }
        }.to_json
      
        req.body = body
      
        response = http.request(req)
            
        if response.is_a?(Net::HTTPSuccess)
          result = JSON.parse(response.body)

          render json: result
        else
          render json: { error: response.body }, status: :unprocessable_entity
        end
      end

      def generate_custom_model_image
        # Setup the HTTP request to start the generation
        uri = URI.parse("https://firefly-api.adobe.io/v3/images/generate-async")
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
      
        req = Net::HTTP::Post.new(uri.path)
        req["Authorization"] = "Bearer #{@bearer_token}"
        req["x-api-key"] = @client_id
        req["Content-Type"] = "application/json"
        req["x-model-version"] = "image4_custom"
      
        permitted_params = params.require(:firefly).permit(:prompt)
      
        prompt = permitted_params[:prompt]
      
        body = {
          "prompt" => prompt,
          "contentClass" => "photo",
          "customModelId" => "urn:aaid:sc:VA6C2:baf71dd5-653c-448a-bbed-b8b80aaf2220",
        }.to_json
      
        req.body = body
        initial_response = http.request(req)
      
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
        uri = URI.parse('https://firefly-api.adobe.io/v3/images/expand')
        permitted_params = params.require(:firefly).permit(:width, :height, :firefly_image_id)
        
      
        body = {
          size: { width: permitted_params[:width], height: permitted_params[:height] },
          image: { source: { uploadId: permitted_params[:firefly_image_id] } }
        }
      
        req = Net::HTTP::Post.new(uri)
        req['X-Api-Key'] = @client_id
        req['Authorization'] = "Bearer #{@bearer_token}"
        req['Content-Type'] = 'application/json'
        req.body = body.to_json
      
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
      
        response = http.request(req)

        if response.is_a?(Net::HTTPSuccess)
            result = JSON.parse(response.body)
  
            render json: { expanded_image_url: result['outputs'][0]['image']['url'] }

        else
            render json: { error: response.body }, status: :unprocessable_entity
        end
      end

      def fill_image
        # Setup the HTTP request
        uri = URI.parse('https://firefly-api.adobe.io/v3/images/fill')
        permitted_params = params.require(:firefly).permit(:mask_id, :source_id, :prompt)
      
        body = {
          image: {
            mask: {
              uploadId: permitted_params[:mask_id],
            },
            source: {
              uploadId: permitted_params[:source_id],
            },
          },
          prompt: permitted_params[:prompt],
        }
      
        req = Net::HTTP::Post.new(uri)
        req['X-Api-Key'] = @client_id
        req['Authorization'] = "Bearer #{@bearer_token}"
        req['Content-Type'] = 'application/json'
        req.body = body.to_json
      
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
      
        response = http.request(req)

        if response.is_a?(Net::HTTPSuccess)
            result = JSON.parse(response.body)
  
            render json: { filled_image_url: result['outputs'][0]['image']['url'] }
        else
            render json: { error: response.body }, status: :unprocessable_entity
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
        req['Authorization'] = "Bearer #{@bearer_token}"
        req['x-api-key'] = @client_id
        req['Content-Type'] = 'application/json'
      
        response = http.request(req)
        JSON.parse(response.body)
      end
  end