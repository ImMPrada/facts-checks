FactoryBot.define do
  factory :disseminator_url do
    url { Faker::Internet.url }
    association :disseminator
  end
end
