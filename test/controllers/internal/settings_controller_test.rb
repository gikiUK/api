require "test_helper"

class Internal::SettingsControllerTest < ApplicationControllerTest
  setup do
    setup_user
  end

  # Auth guards
  guard_incorrect_token! :internal_settings_path, method: :get
  guard_incorrect_token! :locale_internal_settings_path, method: :patch

  test "GET show returns user settings" do
    get internal_settings_path, as: :json

    assert_response :success
    assert_json_response({
      settings: SerializeSettings.(@current_user)
    })
  end

  test "PATCH locale updates successfully" do
    patch locale_internal_settings_path, params: { value: "hu" }, as: :json

    assert_response :success
    assert_equal "hu", @current_user.reload.locale
    assert_json_response({
      settings: SerializeSettings.(@current_user)
    })
  end

  test "PATCH locale fails with invalid locale" do
    patch locale_internal_settings_path, params: { value: "invalid" }, as: :json

    assert_response :unprocessable_entity
    assert_equal "en", @current_user.reload.locale

    json = response.parsed_body
    assert_equal "validation_error", json["error"]["type"]
    assert_equal "Locale update failed", json["error"]["message"]
  end
end
