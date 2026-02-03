require "test_helper"

class SerializeUserTest < ActiveSupport::TestCase
  test "serializes user with id" do
    user = create(:user)

    result = SerializeUser.(user)

    assert_equal({ id: user.id }, result)
  end
end
