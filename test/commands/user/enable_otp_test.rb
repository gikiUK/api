require "test_helper"

class User::EnableOtpTest < ActiveSupport::TestCase
  test "enables OTP for user with secret" do
    user = create(:user)
    user.data.update!(otp_secret: ROTP::Base32.random)

    assert_nil user.otp_enabled_at # Sanity

    User::EnableOtp.(user)

    user.reload
    assert user.otp_enabled_at.present?
    assert user.otp_enabled?
  end

  test "sets otp_enabled_at to current time" do
    user = create(:user)
    user.data.update!(otp_secret: ROTP::Base32.random)

    freeze_time do
      User::EnableOtp.(user)
      assert_equal Time.current, user.reload.otp_enabled_at
    end
  end
end
