class PhotoshopController < ApplicationController
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
  
    def perform_actions
      input_file = params[:input_file]
      actions_file = params[:actions_file]
  
      if input_file.blank? || actions_file.blank?
        render json: { error: 'Missing input or actions file' }, status: :bad_request
        return
      end
  
      begin
        aws_service = PresignedUrlService.new
        urls = aws_service.generate_urls
  
        aws_service.upload_to_presigned_url(urls[:input][:put_url], input_file)
        aws_service.upload_to_presigned_url(urls[:action][:put_url], actions_file)
        
        adobe_response = call_photoshop_api(
          urls[:input][:get_url],    
          urls[:action][:get_url],  
          urls[:output][:put_url]    
        )
  
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
  
    private
  
    def call_photoshop_api(input_url, actions_url, output_url)
      url = URI.parse('https://image.adobe.io/pie/psdService/photoshopActions')
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
  
      req = Net::HTTP::Post.new(url.path)
      req['Authorization'] = "Bearer #{@bearer_token}"
      req['x-api-key'] = @client_id
      req['Content-Type'] = 'application/json'
      req.body = {
        inputs: [{ href: input_url, storage: "external" }],
        options: { actions: [{ href: actions_url, storage: "external" }] },
        outputs: [{ href: output_url, storage: "external", type: "image/jpeg" }]
      }.to_json
  
      response = http.request(req)
      JSON.parse(response.body)
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
  end