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
end
