require "test_helper"

class Auth::RegistrationsControllerTest < ApplicationControllerTest
  test "POST signup creates a new user with valid params" do
    assert_difference("User.count", 1) do
      post user_registration_path, params: {
        user: {
          email: "newuser@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }, as: :json
    end

    assert_response :created

    json = response.parsed_body
    assert_equal "newuser@example.com", json["user"]["email"]
  end

  test "POST signup creates a session for the user" do
    post user_registration_path, params: {
      user: {
        email: "newuser@example.com",
        password: "password123",
        password_confirmation: "password123"
      }
    }, as: :json

    assert_response :created

    # User should be signed in - accessing authenticated endpoint should succeed
    get internal_me_path, as: :json
    assert_response :ok
  end

  test "POST signup returns error with invalid email" do
    assert_no_difference("User.count") do
      post user_registration_path, params: {
        user: {
          email: "invalid-email",
          password: "password123",
          password_confirmation: "password123"
        }
      }, as: :json
    end

    assert_response :unprocessable_entity

    json = response.parsed_body
    assert_equal "validation_error", json["error"]["type"]
    assert_equal "Validation failed", json["error"]["message"]
    assert json["error"]["errors"]["email"].present?
  end

  test "POST signup returns error with password mismatch" do
    assert_no_difference("User.count") do
      post user_registration_path, params: {
        user: {
          email: "newuser@example.com",
          password: "password123",
          password_confirmation: "different123"
        }
      }, as: :json
    end

    assert_response :unprocessable_entity

    json = response.parsed_body
    assert_equal "validation_error", json["error"]["type"]
    assert json["error"]["errors"]["password_confirmation"].present?
  end

  test "POST signup returns error with duplicate email" do
    create(:user, email: "existing@example.com")

    assert_no_difference("User.count") do
      post user_registration_path, params: {
        user: {
          email: "existing@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }, as: :json
    end

    assert_response :unprocessable_entity

    json = response.parsed_body
    assert_equal "validation_error", json["error"]["type"]
    assert json["error"]["errors"]["email"].present?
  end

  test "POST signup returns error with short password" do
    assert_no_difference("User.count") do
      post user_registration_path, params: {
        user: {
          email: "newuser@example.com",
          password: "short",
          password_confirmation: "short"
        }
      }, as: :json
    end

    assert_response :unprocessable_entity

    json = response.parsed_body
    assert_equal "validation_error", json["error"]["type"]
    assert json["error"]["errors"]["password"].present?
  end
end
