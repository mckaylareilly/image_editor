class ImagesController < ApplicationController
  def create
    # Create a new image
    @image = Image.new(image_params)
    
    # If image saves, render a JSON with the ID, URL and created at
    if @image.save
      image_url = url_for(@image.file) # Get the ActiveStorage url
      render json: { id: @image.id, imageUrl: image_url, created_at: @image.created_at }, status: :created
    else
      render json: { errors: @image.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  # Permits only certain params for security reasons
  def image_params
    params.require(:image).permit(:file)
  end
end