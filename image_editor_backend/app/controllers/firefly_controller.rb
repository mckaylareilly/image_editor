class FireflyController < ApplicationController
    before_action :get_token
  
    def get_token
      @client_id = 'c2e303e975b4411f8c6b04f3cfc47e23'
      client_secret = 'p8e-ndlKdIpt9ajGDsb3jud2-WClgZhf_DHH'
  
      begin
        response = RestClient.post('https://ims-na1.adobelogin.com/ims/token/v3', {
          client_id: @client_id,
          client_secret: client_secret,
          grant_type: 'client_credentials',
          scope: 'openid, AdobeID, session, additional_info, read_organizations, firefly_api, ff_apis'
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
          "prompt" => prompt, # Use the prompt parameter passed from the front end
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

      #Expands the background of an image using Firefly's Expand API
      def expand_image
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
  end