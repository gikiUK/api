require "test_helper"

class Internal::MeControllerTest < ApplicationControllerTest
  guard_incorrect_token! :internal_me_path

  test "returns serialized user" do
    user = create(:user)
    sign_in_user(user)

    get internal_me_path, as: :json

    assert_response :success
    assert_json_response(SerializeUser.(user))
  end
end
