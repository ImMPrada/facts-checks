FactoryBot.define do
  factory :veredict do
    name { Faker::Lorem.unique.word }
  end
end
