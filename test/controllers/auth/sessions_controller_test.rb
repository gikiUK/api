require "test_helper"

class Auth::SessionsControllerTest < ApplicationControllerTest
  setup do
    @user = create(:user, email: "test@example.com", password: "password123")
  end

  test "POST login returns success with valid credentials" do
    post user_session_path, params: {
      user: {
        email: "test@example.com",
        password: "password123"
      }
    }, as: :json

    assert_response :ok

    json = response.parsed_body
    assert_equal "success", json["status"]
  end

  test "POST login establishes session" do
    post user_session_path, params: {
      user: {
        email: "test@example.com",
        password: "password123"
      }
    }, as: :json

    assert_response :ok

    # Verify user is signed in by accessing an authenticated endpoint
    get internal_me_path, as: :json
    assert_response :ok
  end

  test "POST login returns error with invalid password" do
    post user_session_path, params: {
      user: {
        email: "test@example.com",
        password: "wrongpassword"
      }
    }, as: :json

    assert_response :unauthorized

    json = response.parsed_body
    assert_equal "unauthorized", json["error"]["type"]
    assert json["error"]["message"].present?
  end

  test "POST login returns error with non-existent email" do
    post user_session_path, params: {
      user: {
        email: "nonexistent@example.com",
        password: "password123"
      }
    }, as: :json

    assert_response :unauthorized

    json = response.parsed_body
    assert_equal "unauthorized", json["error"]["type"]
    assert json["error"]["message"].present?
  end

  test "POST login returns unconfirmed error for unconfirmed user" do
    create(:user, :unconfirmed, email: "unconfirmed@example.com", password: "password123")

    post user_session_path, params: {
      user: {
        email: "unconfirmed@example.com",
        password: "password123"
      }
    }, as: :json

    assert_response :unauthorized

    json = response.parsed_body
    assert_equal "unconfirmed", json["error"]["type"]
    assert_equal "unconfirmed@example.com", json["error"]["email"]
  end

  test "POST login does not create session for unconfirmed user" do
    create(:user, :unconfirmed, email: "unconfirmed@example.com", password: "password123")

    post user_session_path, params: {
      user: {
        email: "unconfirmed@example.com",
        password: "password123"
      }
    }, as: :json

    assert_response :unauthorized

    # Verify no session was created
    get internal_me_path, as: :json
    assert_response :unauthorized
  end

  test "DELETE logout clears session" do
    sign_in_user(@user)

    delete destroy_user_session_path, as: :json

    assert_response :no_content

    # Verify we're no longer authenticated
    get internal_me_path, as: :json
    assert_response :unauthorized
  end

  # 2FA Tests
  test "POST login for admin without 2FA setup returns 2fa_setup_required" do
    admin = create(:user, :admin, email: "admin@example.com", password: "password123")

    post user_session_path, params: {
      user: { email: "admin@example.com", password: "password123" }
    }, as: :json

    assert_response :ok

    json = response.parsed_body
    assert_equal "2fa_setup_required", json["status"]
    assert json["provisioning_uri"].start_with?("otpauth://totp/Giki:")

    # Verify admin was NOT signed in
    get internal_me_path, as: :json
    assert_response :unauthorized

    # Verify OTP secret was generated
    admin.reload
    assert admin.otp_secret.present?
  end

  test "POST login for admin with 2FA enabled returns 2fa_required" do
    admin = create(:user, :admin, email: "admin@example.com", password: "password123")
    User::GenerateOtpSecret.(admin)
    User::EnableOtp.(admin)

    post user_session_path, params: {
      user: { email: "admin@example.com", password: "password123" }
    }, as: :json

    assert_response :ok
    assert_json_response({ status: "2fa_required" })

    # Verify admin was NOT signed in
    get internal_me_path, as: :json
    assert_response :unauthorized
  end

  test "POST login for admin cannot access internal pages before completing 2FA" do
    admin = create(:user, :admin, email: "admin@example.com", password: "password123")
    User::GenerateOtpSecret.(admin)
    User::EnableOtp.(admin)

    post user_session_path, params: {
      user: { email: "admin@example.com", password: "password123" }
    }, as: :json

    assert_response :ok
    assert_json_response({ status: "2fa_required" })

    # Try to access internal page - should be unauthorized
    get internal_me_path, as: :json
    assert_response :unauthorized
  end

  test "POST login for non-admin signs in normally" do
    post user_session_path, params: {
      user: { email: "test@example.com", password: "password123" }
    }, as: :json

    assert_response :ok
    assert_json_response({ status: "success" })

    # Verify user IS signed in
    get internal_me_path, as: :json
    assert_response :ok
  end

  test "POST login for non-admin with 2FA enabled returns 2fa_required" do
    user = create(:user, email: "otp-user@example.com", password: "password123")
    User::GenerateOtpSecret.(user)
    User::EnableOtp.(user)

    post user_session_path, params: {
      user: { email: "otp-user@example.com", password: "password123" }
    }, as: :json

    assert_response :ok
    assert_json_response({ status: "2fa_required" })

    # Verify user was NOT signed in
    get internal_me_path, as: :json
    assert_response :unauthorized
  end
end
