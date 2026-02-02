require "test_helper"

class Admin::BaseControllerTest < ApplicationControllerTest
  class TestController < Admin::BaseController
    def test_action
      render json: { success: true }
    end
  end

  setup do
    Rails.application.routes.draw do
      devise_for :users

      namespace :admin do
        get "test", to: "base_controller_test/test#test_action"
      end
    end
  end

  teardown do
    Rails.application.reload_routes!
  end

  test "returns 401 for non-authenticated users" do
    get "/admin/test", as: :json

    assert_response :unauthorized
    assert_equal "unauthorized", response.parsed_body["error"]["type"]
  end

  test "returns 403 for authenticated non-admin users" do
    user = create(:user, admin: false)
    sign_in_user(user)

    get "/admin/test", as: :json

    assert_response :forbidden
    assert_json_response({
      error: {
        type: "forbidden",
        message: "Admin access required"
      }
    })
  end

  test "allows access for authenticated admin users" do
    admin = create(:user, :admin)
    sign_in_user(admin)

    get "/admin/test", as: :json

    assert_response :success
    assert_json_response({ success: true })
  end
end
