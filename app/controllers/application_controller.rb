class ApplicationController < ActionController::API
  include ActionController::Cookies

  private
  def render_error(status_code, error_type, extra = {})
    render json: {
      error: { type: error_type.to_s, message: I18n.t("api_errors.#{error_type}") }.merge(extra)
    }, status: status_code
  end

  def render_401(error_type = :unauthenticated, **extra) = render_error(:unauthorized, error_type, extra)
  def render_403(error_type = :forbidden, **extra) = render_error(:forbidden, error_type, extra)
  def render_404(error_type = :not_found, **extra) = render_error(:not_found, error_type, extra)
  def render_422(error_type, **extra) = render_error(:unprocessable_entity, error_type, extra)

  def render_success(message_type, status: :ok, **interpolations)
    render json: { message: I18n.t("api_messages.#{message_type}", **interpolations) }, status: status
  end

  def sign_in_with_2fa_guard!(user)
    # Admins MUST have 2FA - generate secret if not set up
    if user.requires_otp? && !user.otp_enabled?
      warden.logout(:user)
      session[:otp_user_id] = user.id
      session[:otp_timestamp] = Time.current.to_i

      User::GenerateOtpSecret.(user)
      render json: {
        status: "2fa_setup_required",
        provisioning_uri: user.otp_provisioning_uri
      }, status: :ok
      return
    end

    # Anyone with 2FA enabled (admin or not) must verify
    if user.otp_enabled?
      warden.logout(:user)
      session[:otp_user_id] = user.id
      session[:otp_timestamp] = Time.current.to_i

      render json: { status: "2fa_required" }, status: :ok
      return
    end

    # User is already signed in by warden.authenticate
    render json: { status: "success" }, status: :ok
  end
end
