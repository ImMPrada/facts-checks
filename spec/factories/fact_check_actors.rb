FactoryBot.define do
  factory :fact_check_actor do
    association :fact_check
    association :actor
    association :actor_role
  end
end
