class Veredict < ApplicationRecord
  has_many :fact_checks, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
end
