class DisseminatorUrl < ApplicationRecord
  validates :url, presence: true
  validates :disseminator, presence: true

  belongs_to :disseminator
end
