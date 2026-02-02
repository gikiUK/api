class User::Data < ApplicationRecord
  belongs_to :user

  before_create :generate_unsubscribe_token!
  before_create :set_default_timezone!

  DEFAULT_TIMEZONE = "UTC".freeze

  def email_valid? = email_bounced_at.nil?
  def may_receive_emails? = email_complaint_at.nil?

  private
  def generate_unsubscribe_token!
    self.unsubscribe_token ||= SecureRandom.uuid
  end

  def set_default_timezone!
    self.timezone ||= DEFAULT_TIMEZONE
  end
end
