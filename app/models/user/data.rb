class User::Data < ApplicationRecord
  belongs_to :user

  before_create :generate_unsubscribe_token!
  before_create :set_default_timezone!
  before_create :set_default_locale!

  validates :locale, presence: true, inclusion: { in: I18n::SUPPORTED_LOCALES }

  def email_valid? = email_bounced_at.nil?
  def may_receive_emails? = email_complaint_at.nil?

  private
  def generate_unsubscribe_token!
    self.unsubscribe_token ||= SecureRandom.uuid
  end

  def set_default_timezone!
    self.timezone ||= "UTC".freeze
  end

  def set_default_locale!
    self.locale ||= I18n.default_locale.to_s
  end
end
