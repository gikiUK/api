require "test_helper"

class User::DataTest < ActiveSupport::TestCase
  test "generates unsubscribe_token on create" do
    user = create(:user)

    assert_not_nil user.data.unsubscribe_token
    assert_match(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i,
                 user.data.unsubscribe_token)
  end

  test "does not override existing unsubscribe_token" do
    user = build(:user)
    user.data.unsubscribe_token = "custom-token-12345"
    user.save!

    assert_equal "custom-token-12345", user.data.unsubscribe_token
  end

  test "timezone defaults to UTC on create" do
    user = create(:user)

    assert_equal "UTC", user.data.timezone
  end

  test "timezone is not overridden when provided" do
    user = build(:user)
    user.data.timezone = "America/New_York"
    user.save!

    assert_equal "America/New_York", user.data.timezone
  end

  test "notifications_enabled defaults to true" do
    user = create(:user)

    assert user.data.notifications_enabled
  end

  test "receive_newsletters defaults to true" do
    user = create(:user)

    assert user.data.receive_newsletters
  end

  test "email_valid? returns true when email_bounced_at is nil" do
    user = create(:user)

    assert user.data.email_valid?
  end

  test "email_valid? returns false when email has bounced" do
    user = create(:user, :with_bounced_email)

    refute user.data.email_valid?
  end

  test "may_receive_emails? returns true when no complaint" do
    user = create(:user)

    assert user.data.may_receive_emails?
  end

  test "may_receive_emails? returns false when complaint received" do
    user = create(:user, :with_email_complaint)

    refute user.data.may_receive_emails?
  end
end
