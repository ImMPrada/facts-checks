FactoryBot.define do
  factory :platform do
    name { Faker::Lorem.unique.word }
  end
end
