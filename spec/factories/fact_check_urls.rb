FactoryBot.define do
  factory :fact_check_url do
    url { Faker::Internet.unique.url }
    source { :colombia_check }
    digested { false }
    attempts { 0 }

    trait :digested do
      digested { true }
      digested_at { Time.current }
    end

    trait :with_error do
      last_error { "Failed to scrape: #{Faker::Lorem.sentence}" }
      attempts { 1 }
    end

    trait :multiple_attempts do
      attempts { 3 }
    end
  end
end
