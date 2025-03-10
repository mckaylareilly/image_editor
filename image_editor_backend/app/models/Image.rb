class Image < ApplicationRecord
    has_one_attached :file # Setup ActiveStorage association
    has_many :transformed_image
  
    validates :file, presence: true
end