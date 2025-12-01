class FactCheckActor < ApplicationRecord
  validates :fact_check, presence: true
  validates :actor, presence: true
  validates :actor_role, presence: true
  validates :actor_id, uniqueness: { scope: [ :fact_check_id, :actor_role_id ] }

  belongs_to :fact_check
  belongs_to :actor
  belongs_to :actor_role
end
