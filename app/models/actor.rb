class Actor < ApplicationRecord
  validates :name, presence: true
  validates :actor_type, presence: true

  belongs_to :actor_type
  has_many :fact_check_actors, dependent: :restrict_with_error
  has_many :fact_checks, through: :fact_check_actors
end
