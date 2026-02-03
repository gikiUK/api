require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "creates user with valid email and password" do
    user = create(:user)
    assert user.persisted?
    assert user.valid_password?("password123")
  end

  test "requires email" do
    user = build(:user, email: nil)
    assert_not user.valid?
  end

  test "requires password" do
    user = build(:user, password: nil)
    assert_not user.valid?
  end

  test "rejects invalid password" do
    user = create(:user)
    assert_not user.valid_password?("wrong_password")
  end

  test "automatically creates data record on user creation" do
    user = create(:user)

    assert user.data.present?
    assert_instance_of User::Data, user.data
    assert user.data.persisted?
  end

  test "delegates unknown methods to data record" do
    user = create(:user)
    user.data.update!(timezone: "America/Los_Angeles")

    assert_equal "America/Los_Angeles", user.timezone
  end

  test "respond_to? returns true for data record methods" do
    user = create(:user)

    assert_respond_to user, :timezone
    assert_respond_to user, :unsubscribe_token
    assert_respond_to user, :notifications_enabled
  end

  test "raises NoMethodError for truly unknown methods" do
    user = create(:user)

    assert_raises NoMethodError do
      user.completely_unknown_method
    end
  end

  test "data record is destroyed when user is destroyed" do
    user = create(:user)
    data_id = user.data.id

    user.destroy!

    refute User::Data.exists?(data_id)
  end

  # Two-Factor Authentication Tests
  test "otp_enabled? returns false when no otp_secret" do
    user = create(:user)
    refute user.otp_enabled?
  end

  test "otp_enabled? returns false when otp_secret but no otp_enabled_at" do
    user = create(:user)
    user.data.update!(otp_secret: ROTP::Base32.random)
    refute user.otp_enabled?
  end

  test "otp_enabled? returns true when both otp_secret and otp_enabled_at present" do
    user = create(:user)
    user.data.update!(otp_secret: ROTP::Base32.random, otp_enabled_at: Time.current)
    assert user.otp_enabled?
  end

  test "requires_otp? returns true for admin users" do
    user = create(:user, :admin)
    assert user.requires_otp?
  end

  test "requires_otp? returns false for non-admin users" do
    user = create(:user)
    refute user.requires_otp?
  end

  test "otp_provisioning_uri returns nil when no otp_secret" do
    user = create(:user)
    assert_nil user.otp_provisioning_uri
  end

  test "otp_provisioning_uri returns valid URI when otp_secret present" do
    user = create(:user)
    User::GenerateOtpSecret.(user)

    uri = user.otp_provisioning_uri
    assert uri.present?
    assert uri.start_with?("otpauth://totp/Giki:")
    assert uri.include?(URI.encode_www_form_component(user.email))
  end

  # Company Association Tests
  test "has many company_memberships" do
    user = create(:user)
    company1 = create(:company)
    company2 = create(:company)

    user.company_memberships.create!(company: company1)
    user.company_memberships.create!(company: company2)

    assert_equal 2, user.company_memberships.count
  end

  test "has many companies through company_memberships" do
    user = create(:user)
    company1 = create(:company)
    company2 = create(:company)

    user.company_memberships.create!(company: company1)
    user.company_memberships.create!(company: company2)

    assert_equal 2, user.companies.count
    assert_includes user.companies, company1
    assert_includes user.companies, company2
  end

  test "company_memberships are destroyed when user is destroyed" do
    user = create(:user)
    company = create(:company)
    membership = user.company_memberships.create!(company: company)
    membership_id = membership.id

    user.destroy!

    refute CompanyMembership.exists?(membership_id)
  end
end
