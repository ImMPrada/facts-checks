class FactCheckTopic < ApplicationRecord
  validates :fact_check, presence: true
  validates :topic, presence: true
  validates :topic_id, uniqueness: { scope: :fact_check_id }

  belongs_to :fact_check
  belongs_to :topic
end
