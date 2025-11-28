FactoryBot.define do
  factory :publication_date do
    date { Faker::Date.unique.backward(days: 365) }
  end
end
