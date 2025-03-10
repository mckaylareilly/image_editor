class TransformedImage < ApplicationRecord
    belongs_to :image  
    has_one_attached :file # Setup ActiveStorage association

    validates :file, presence: true
end