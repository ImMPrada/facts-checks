class FactCheckDisseminator < ApplicationRecord
  validates :fact_check, presence: true
  validates :disseminator, presence: true
  validates :disseminator_id, uniqueness: { scope: :fact_check_id }

  belongs_to :fact_check
  belongs_to :disseminator
end
