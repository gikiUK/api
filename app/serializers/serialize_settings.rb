class SerializeSettings
  include Mandate

  initialize_with :user

  def call
    {
      locale: user.locale,
      receive_newsletters: user.receive_newsletters?,
      notifications_enabled: user.notifications_enabled?
    }
  end
end
