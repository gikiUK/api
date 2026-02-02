require "test_helper"

class External::BaseControllerTest < ApplicationControllerTest
  class TestController < External::BaseController
    def test_action
      render json: { success: true }
    end
  end

  setup do
    Rails.application.routes.draw do
      devise_for :users

      namespace :external do
        get "test", to: "base_controller_test/test#test_action"
      end
    end
  end

  teardown do
    Rails.application.reload_routes!
  end

  test "allows access without authentication" do
    get "/external/test", as: :json

    assert_response :success
    assert_json_response({ success: true })
  end
end
