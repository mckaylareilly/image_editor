Rails.application.routes.draw do
  resources :images
  resources :transformed_images

  post 'expand_image', to: 'firefly#expand_image'
  post 'upload_image', to: 'firefly#upload_image'
  post 'generate_image', to: 'firefly#generate_image'
  post 'fill_image', to: 'firefly#fill_image'
end
