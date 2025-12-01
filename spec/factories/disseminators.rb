FactoryBot.define do
  factory :disseminator do
    name { Faker::Internet.username }
    association :platform
  end
end
