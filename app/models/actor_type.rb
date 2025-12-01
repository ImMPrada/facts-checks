class ActorType < ApplicationRecord
  validates :name, presence: true, uniqueness: true

  has_many :actors, dependent: :restrict_with_error
end
