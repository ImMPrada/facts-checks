FactoryBot.define do
  factory :fact_check do
    source_url { Faker::Internet.unique.url }
    title { Faker::Lorem.sentence }
    reasoning { Faker::Lorem.paragraph }
    digested { false }

    association :veredict

    trait :with_publication_date do
      association :publication_date
    end

    trait :digested do
      digested { true }
    end
  end
end
