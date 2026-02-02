class Auth::RegistrationsController < Devise::RegistrationsController
  respond_to :json

  private
  def respond_with(resource, _opts = {})
    if resource.persisted?
      if resource.active_for_authentication?
        # User is confirmed - sign them in and return full data
        sign_in(resource_name, resource)
        render json: { user: { id: resource.id, email: resource.email } }, status: :created
      else
        # User needs to confirm email - return minimal data
        render json: { user: { email: resource.email, email_confirmed: false } }, status: :created
      end
    else
      render json: {
        error: {
          type: "validation_error",
          message: "Validation failed",
          errors: resource.errors.messages
        }
      }, status: :unprocessable_entity
    end
  end

  def sign_up_params
    params.require(:user).permit(:email, :password, :password_confirmation)
  end
end
