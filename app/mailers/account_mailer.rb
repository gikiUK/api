class AccountMailer < ApplicationMailer
  self.email_category = :transactional

  def welcome(user)
    @login_url = "#{Giki.config.frontend_base_url}/login"
    mail_to_user(user)
  end
end
