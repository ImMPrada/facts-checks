class Platform < ApplicationRecord
  validates :name, presence: true, uniqueness: true

  has_many :disseminators, dependent: :restrict_with_error
end
