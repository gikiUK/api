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
    refute json["user"]["email_confirmed"]
  end

  test "POST signup calls User::Bootstrap" do
    User::Bootstrap. expects(:call).with(instance_of(User)).once

    post user_registration_path, params: {
      user: {
        email: "newuser@example.com",
        password: "password123",
        password_confirmation: "password123"
      }
    }, as: :json

    assert_response :created
  end

  test "POST signup does not call User::Bootstrap on validation failure" do
    User::Bootstrap.expects(:call).never

    post user_registration_path, params: {
      user: {
        email: "invalid-email",
        password: "password123",
        password_confirmation: "password123"
      }
    }, as: :json

    assert_response :unprocessable_entity
  end

  test "POST signup does not create session for unconfirmed user" do
    post user_registration_path, params: {
      user: {
        email: "newuser@example.com",
        password: "password123",
        password_confirmation: "password123"
      }
    }, as: :json

    assert_response :created

    # User should not be signed in - accessing authenticated endpoint should fail
    get internal_me_path, as: :json
    assert_response :unauthorized
  end

  test "POST signup sends confirmation email" do
    assert_difference "ActionMailer::Base.deliveries.size", 1 do
      post user_registration_path, params: {
        user: {
          email: "newuser@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }, as: :json
    end

    assert_response :created

    email = ActionMailer::Base.deliveries.last
    assert_equal [ "newuser@example.com" ], email.to
    assert_includes email.subject.downcase, "confirm"
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
