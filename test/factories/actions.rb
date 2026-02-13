FactoryBot.define do
  factory :action do
    title { Faker::Lorem.sentence(word_count: 4) }

    trait :with_airtable_id do
      airtable_id { SecureRandom.alphanumeric(17) }
    end

    trait :disabled do
      enabled { false }
    end
  end
end
