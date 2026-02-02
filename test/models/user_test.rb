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
end
