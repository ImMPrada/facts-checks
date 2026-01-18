FactoryBot.define do
  factory :fact_check_disseminator do
    association :fact_check
    association :disseminator
  end
end
