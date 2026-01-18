FactoryBot.define do
  factory :actor_role do
    name { Faker::Lorem.unique.word }
  end
end
