class Disseminator < ApplicationRecord
  validates :name, presence: true
  validates :platform, presence: true

  belongs_to :platform
  has_many :disseminator_urls, dependent: :destroy
  has_many :fact_check_disseminators, dependent: :restrict_with_error
  has_many :fact_checks, through: :fact_check_disseminators
end
