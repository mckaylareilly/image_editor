Rails.application.routes.draw do
  resources :images
  resources :transformed_images

  post 'expand_image', to: 'firefly#expand_image'
  post 'upload_image', to: 'firefly#upload_image'
  post 'generate_image', to: 'firefly#generate_image'
  post 'fill_image', to: 'firefly#fill_image'
  post 'generate_custom_model_image', to: 'firefly#generate_custom_model_image'


  post 'perform_actions', to: 'photoshop#perform_actions'
  post 'perform_action_json', to: 'photoshop#perform_action_json'
  post 'remove_background', to: 'photoshop#remove_background'
  post 'create_mask', to: 'photoshop#create_mask'


end
