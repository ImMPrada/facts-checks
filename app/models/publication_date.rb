class PublicationDate < ApplicationRecord
  has_many :fact_checks, dependent: :restrict_with_error

  validates :date, presence: true, uniqueness: { case_sensitive: false }
end
