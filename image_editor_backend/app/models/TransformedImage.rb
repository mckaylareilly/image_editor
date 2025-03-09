class TransformedImage < ApplicationRecord
    belongs_to :image  
    has_one_attached :file

    validates :file, presence: true
end