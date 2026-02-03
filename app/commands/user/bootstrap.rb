class User::Bootstrap
  include Mandate

  initialize_with :user

  def call
    AccountMailer.welcome(user).deliver_later
  end
end
