class Book < ApplicationRecord
    belongs_to :category, optional: true

    validates :title, presence: true
    validates :price, presence: true
    validates :rating, presence: true
end