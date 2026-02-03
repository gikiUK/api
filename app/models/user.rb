class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :validatable, :confirmable

  has_one :data, dependent: :destroy, class_name: "User::Data", autosave: true

  after_initialize do
    build_data if new_record? && !data
  end

  # Two-Factor Authentication
  def otp_enabled? = otp_secret.present? && otp_enabled_at.present?
  def requires_otp? = admin?
  def otp_provisioning_uri = otp_secret ? ROTP::TOTP.new(otp_secret, issuer: "Giki").provisioning_uri(email) : nil

  def method_missing(name, *args)
    super
  rescue NameError
    raise unless data.respond_to?(name)

    data.send(name, *args)
  end

  def respond_to_missing?(name, *args)
    super || data.respond_to?(name)
  end

  # Don't rely on respond_to_missing? which n+1s a data record
  # https://tenderlovemaking.com/2011/06/28/til-its-ok-to-return-nil-from-to_ary.html
  def to_ary = nil
end
