class ActorRole < ApplicationRecord
  validates :name, presence: true, uniqueness: true

  has_many :fact_check_actors, dependent: :restrict_with_error
end
