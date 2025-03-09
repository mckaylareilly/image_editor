require 'open-uri'

class TransformedImagesController < ApplicationController
    def create
        url = params[:transformed_image][:file]
        io = OpenURI.open_uri(url)  # Use OpenURI.open_uri here
      
        @transformed_image = TransformedImage.new(image_id: params[:transformed_image][:image_id])
      
        # Attach the file
        @transformed_image.file.attach(io: io, filename: 'transformed_image.jpg') # Adjust filename as needed
    
        if @transformed_image.save
          render json: @transformed_image, status: :created
        else
          render json: { error: @transformed_image.errors.full_messages }, status: :unprocessable_entity
        end
      end
  
    def index
        @transformed_images = TransformedImage.includes(:image).all
      
        # Generate ActiveStorage URLs for both original and transformed images
        image_pairs = @transformed_images.map do |transformed_image|
            original_image_url = transformed_image.image&.file&.attached? ? url_for(transformed_image.image.file) : nil
            transformed_image_url = transformed_image.file.attached? ? url_for(transformed_image.file) : nil
      
          { original_image_url: original_image_url, transformed_image_url: transformed_image_url }
        end
        
        render json: image_pairs
    end
  
    private
  
    def image_params
        params.require(:transformed_image).permit(:file, :image_id)
    end
  end