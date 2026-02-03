require "test_helper"

class Auth::PasswordsControllerTest < ApplicationControllerTest
  setup do
    @user = create(:user, email: "test@example.com", password: "oldpassword123")
  end

  test "POST password reset sends reset instructions" do
    assert_emails 1 do
      post user_password_path, params: {
        user: {
          email: "test@example.com"
        }
      }, as: :json
    end

    assert_response :ok
    assert_json_response({ message: api_error_msg(:password_reset_sent, email: "test@example.com") })

    email = ActionMailer::Base.deliveries.last
    assert_equal [ "test@example.com" ], email.to
  end

  test "POST password reset with non-existent email still returns success (security)" do
    post user_password_path, params: {
      user: {
        email: "nonexistent@example.com"
      }
    }, as: :json

    assert_response :ok
    assert_json_response({ message: api_error_msg(:password_reset_sent, email: "nonexistent@example.com") })
  end

  test "PATCH password reset updates password with valid token" do
    # Generate a reset token for the user
    token = @user.send_reset_password_instructions

    patch user_password_path, params: {
      user: {
        reset_password_token: token,
        password: "newpassword123",
        password_confirmation: "newpassword123"
      }
    }, as: :json

    assert_response :ok
    assert_json_response({ message: api_error_msg(:password_reset_success) })

    # Verify the user can login with new password
    post user_session_path, params: {
      user: {
        email: "test@example.com",
        password: "newpassword123"
      }
    }, as: :json

    assert_response :ok
  end

  test "PATCH password reset fails with invalid token" do
    patch user_password_path, params: {
      user: {
        reset_password_token: "invalid_token",
        password: "newpassword123",
        password_confirmation: "newpassword123"
      }
    }, as: :json

    assert_json_error(:unprocessable_entity, error_type: :invalid_token, errors: { reset_password_token: [ "is invalid" ] })
  end

  test "PATCH password reset fails with password mismatch" do
    token = @user.send_reset_password_instructions

    patch user_password_path, params: {
      user: {
        reset_password_token: token,
        password: "newpassword123",
        password_confirmation: "differentpassword"
      }
    }, as: :json

    assert_json_error(:unprocessable_entity, error_type: :invalid_token, errors: { password_confirmation: [ "doesn't match Password" ] })
  end

  test "PATCH password reset fails with short password" do
    token = @user.send_reset_password_instructions

    patch user_password_path, params: {
      user: {
        reset_password_token: token,
        password: "short",
        password_confirmation: "short"
      }
    }, as: :json

    assert_json_error(:unprocessable_entity, error_type: :invalid_token, errors: { password: [ "is too short (minimum is 6 characters)" ] })
  end
end
