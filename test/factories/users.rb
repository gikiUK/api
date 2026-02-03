FactoryBot.define do
  factory :user do
    email { Faker::Internet.unique.email }
    password { "password123" }
    password_confirmation { password }
    confirmed_at { Time.current }

    trait :admin do
      admin { true }
    end

    trait :unconfirmed do
      confirmed_at { nil }
    end

    trait :with_bounced_email do
      after(:create) do |user|
        user.data.update!(email_bounced_at: Time.current, email_bounce_reason: "permanent")
      end
    end

    trait :with_email_complaint do
      after(:create) do |user|
        user.data.update!(email_complaint_at: Time.current, email_complaint_type: "abuse")
      end
    end

    trait :unsubscribed do
      after(:create) do |user|
        user.data.update!(notifications_enabled: false)
      end
    end

    trait :hungarian do
      after(:create) do |user|
        user.data.update!(locale: "hu")
      end
    end
  end
end
