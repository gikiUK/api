require "test_helper"

class Auth::TwoFactorControllerTest < ApplicationControllerTest
  setup do
    @admin = create(:user, :admin, email: "admin@example.com", password: "password123")
  end

  # Verify endpoint tests
  test "POST verify-2fa with valid OTP signs in user" do
    User::GenerateOtpSecret.(@admin)
    User::EnableOtp.(@admin)
    setup_otp_session(@admin)

    otp_code = generate_valid_otp(@admin)

    post auth_verify_2fa_path, params: { otp_code: otp_code }, as: :json

    assert_response :ok
    assert_json_response({ status: "success" })

    # Verify user IS signed in
    get internal_me_path, as: :json
    assert_response :ok
  end

  test "POST verify-2fa with invalid OTP returns error" do
    User::GenerateOtpSecret.(@admin)
    User::EnableOtp.(@admin)
    setup_otp_session(@admin)

    post auth_verify_2fa_path, params: { otp_code: "000000" }, as: :json

    assert_response :unauthorized
    assert_json_response({
      error: { type: "invalid_otp", message: "Invalid verification code" }
    })

    # Verify user is NOT signed in
    get internal_me_path, as: :json
    assert_response :unauthorized
  end

  test "POST verify-2fa without session returns session_expired" do
    User::GenerateOtpSecret.(@admin)
    User::EnableOtp.(@admin)

    otp_code = generate_valid_otp(@admin)

    post auth_verify_2fa_path, params: { otp_code: otp_code }, as: :json

    assert_response :unauthorized
    assert_json_response({
      error: { type: "session_expired", message: "Session expired. Please log in again." }
    })
  end

  test "POST verify-2fa with expired session returns session_expired" do
    User::GenerateOtpSecret.(@admin)
    User::EnableOtp.(@admin)
    setup_otp_session(@admin, timestamp: 10.minutes.ago)

    otp_code = generate_valid_otp(@admin)

    post auth_verify_2fa_path, params: { otp_code: otp_code }, as: :json

    assert_response :unauthorized
    assert_json_response({
      error: { type: "session_expired", message: "Session expired. Please log in again." }
    })
  end

  # Setup endpoint tests
  test "POST setup-2fa with valid OTP enables 2FA and signs in user" do
    # Login will generate a new OTP secret, so we don't pre-generate one
    setup_otp_session(@admin)

    # Reload to get the OTP secret that was generated during login
    @admin.reload
    refute @admin.otp_enabled?
    assert @admin.otp_secret.present?

    otp_code = generate_valid_otp(@admin)

    post auth_setup_2fa_path, params: { otp_code: otp_code }, as: :json

    assert_response :ok

    # Reload to get the updated otp_enabled_at timestamp
    @admin.reload
    assert @admin.otp_enabled?

    assert_json_response({ status: "success" })

    # Verify user IS signed in
    get internal_me_path, as: :json
    assert_response :ok
  end

  test "POST setup-2fa with invalid OTP returns error" do
    # Login will generate OTP secret
    setup_otp_session(@admin)

    post auth_setup_2fa_path, params: { otp_code: "000000" }, as: :json

    assert_response :unauthorized
    assert_json_response({
      error: { type: "invalid_otp", message: "Invalid verification code" }
    })

    # Verify 2FA is NOT enabled
    @admin.reload
    refute @admin.otp_enabled?
  end

  test "POST setup-2fa without session returns session_expired" do
    User::GenerateOtpSecret.(@admin)

    otp_code = generate_valid_otp(@admin)

    post auth_setup_2fa_path, params: { otp_code: otp_code }, as: :json

    assert_response :unauthorized
    assert_json_response({
      error: { type: "session_expired", message: "Session expired. Please log in again." }
    })
  end

  private
  def setup_otp_session(user, timestamp: Time.current)
    post user_session_path, params: {
      user: { email: user.email, password: "password123" }
    }, as: :json

    return unless timestamp != Time.current

    travel_to(timestamp) do
      post user_session_path, params: {
        user: { email: user.email, password: "password123" }
      }, as: :json
    end
  end

  def generate_valid_otp(user)
    totp = ROTP::TOTP.new(user.otp_secret, issuer: "Giki")
    totp.now
  end
end
