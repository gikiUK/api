class User::UpdateLocale
  include Mandate

  initialize_with :user, :new_locale

  def call
    user.data.update!(locale: new_locale)
  end
end
