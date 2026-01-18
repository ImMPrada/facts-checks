FactoryBot.define do
  factory :actor_type do
    name { Faker::Lorem.unique.word }
  end
end
