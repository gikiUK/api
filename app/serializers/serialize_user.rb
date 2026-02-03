class SerializeUser
  include Mandate

  initialize_with :user

  def call
    {
      id: user.id
    }
  end
end
