require "test_helper"

class SerializeSettingsTest < ActiveSupport::TestCase
  test "serializes user settings" do
    user = create(:user)

    result = SerializeSettings.(user)

    expected = {
      locale: "en",
      receive_newsletters: true,
      notifications_enabled: true
    }
    assert_equal expected, result
  end

  test "serializes user with hungarian locale" do
    user = create(:user, :hungarian)

    result = SerializeSettings.(user)

    assert_equal "hu", result[:locale]
  end
end
