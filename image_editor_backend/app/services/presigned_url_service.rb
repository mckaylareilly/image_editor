require 'aws-sdk-s3'
require 'rest-client'
require 'uri'
require 'net/http'


class PresignedUrlService
    def initialize
      @s3_client = Aws::S3::Resource.new(region: 'us-east-1') 
      @bucket = ENV['S3_BUCKET_NAME']
      @presigner = Aws::S3::Presigner.new(client: @s3_client.client)
    end

    def generate_key(type, ext)
      "#{type}/#{SecureRandom.uuid}.#{ext}"
    end

    def extract_key_from_url(url)
        uri = URI.parse(url)
        uri.path[1..] # remove leading '/'
    end

    def generate_put_url(key, expires_in: 3600)
        @presigner.presigned_url(:put_object, bucket: @bucket, key: key, expires_in: expires_in)
    end
      
    def generate_get_url(key, expires_in: 3600)
      @presigner.presigned_url(:get_object, bucket: @bucket, key: key, expires_in: expires_in)
    end
      
    def generate_action_urls
      input_key = generate_key("inputs", "jpg")
      action_key = generate_key("actions", "atn")
      output_key = generate_key("outputs", "jpg")
      
      {
        input: { key: input_key, put_url: generate_put_url(input_key), get_url: generate_get_url(input_key) },
        action: { key: action_key, put_url: generate_put_url(action_key), get_url: generate_get_url(action_key) },
        output: { key: output_key, put_url: generate_put_url(output_key), get_url: generate_get_url(output_key) }
      }
    end

    def upload_to_presigned_url(url, uploaded_file)
      content_type = uploaded_file.content_type
      file_path = uploaded_file.tempfile.path
      
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")
      
      req = Net::HTTP::Put.new(uri)
      req['Content-Type'] = content_type
      req['response-content-type'] = content_type
      req.body = File.read(file_path)
      
      response = http.request(req)
      
      unless response.is_a?(Net::HTTPSuccess)
        raise "Upload failed: #{response.code} #{response.message} — #{response.body}"
      end
    end
end
