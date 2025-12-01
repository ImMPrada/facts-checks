FactoryBot.define do
  factory :actor do
    name { Faker::Name.name }
    association :actor_type
  end
end
