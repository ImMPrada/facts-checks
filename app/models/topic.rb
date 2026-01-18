class Topic < ApplicationRecord
  validates :name, presence: true, uniqueness: true

  has_many :fact_check_topics, dependent: :restrict_with_error
  has_many :fact_checks, through: :fact_check_topics
end
