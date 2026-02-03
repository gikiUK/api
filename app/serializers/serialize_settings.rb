class SerializeSettings
  include Mandate

  initialize_with :user

  def call
    {
      locale: user.locale,
      receive_newsletters: user.data.receive_newsletters,
      notifications_enabled: user.data.notifications_enabled
    }
  end
end
