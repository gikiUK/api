class Auth::RegistrationsController < Devise::RegistrationsController
  respond_to :json

  private
  def respond_with(resource, _opts = {})
    if resource.persisted?
      sign_in(resource_name, resource)
      render json: { user: { id: resource.id, email: resource.email } }, status: :created
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
