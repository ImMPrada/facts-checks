FactoryBot.define do
  factory :fact_check_topic do
    association :fact_check
    association :topic
  end
end
