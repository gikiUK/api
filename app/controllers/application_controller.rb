class ApplicationController < ActionController::API
  include ActionController::Cookies

  private
  def render_not_found(message)
    render json: {
      error: {
        type: "not_found",
        message: message
      }
    }, status: :not_found
  end

  def render_validation_error(exception)
    render json: {
      error: {
        type: "validation_error",
        message: exception.message
      }
    }, status: :unprocessable_entity
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
