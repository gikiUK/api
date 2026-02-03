require "test_helper"

class Internal::BaseControllerTest < ApplicationControllerTest
  class TestController < Internal::BaseController
    def test_action
      render json: { success: true }
    end
  end

  setup do
    Rails.application.routes.draw do
      devise_for :users,
        path: "auth",
        path_names: { sign_in: "login", sign_out: "logout", registration: "signup" },
        controllers: { sessions: "auth/sessions", registrations: "auth/registrations", passwords: "auth/passwords", confirmations: "auth/confirmations" }

      namespace :internal do
        get "test", to: "base_controller_test/test#test_action"
      end
    end
  end

  teardown do
    Rails.application.reload_routes!
  end

  test "returns 401 for non-authenticated users" do
    get "/internal/test", as: :json

    assert_response :unauthorized
    assert_equal "unauthorized", response.parsed_body["error"]["type"]
  end

  test "allows access for authenticated users" do
    user = create(:user)
    sign_in_user(user)

    get "/internal/test", as: :json

    assert_response :success
    assert_json_response({ success: true })
  end
end
