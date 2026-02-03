class Auth::SessionsController < Devise::SessionsController
  respond_to :json

  def create
    self.resource = warden.authenticate(auth_options)
    return respond_with_error if resource.blank?

    unless resource.active_for_authentication?
      return render json: {
        error: { type: "unconfirmed", email: resource.email }
      }, status: :unauthorized
    end

    sign_in_with_2fa_guard!(resource)
  end

  private
  def respond_with_error
    render json: {
      error: { type: "unauthorized", message: "Invalid email or password" }
    }, status: :unauthorized
  end

  def respond_to_on_destroy(non_navigational_status: :no_content)
    render json: {}, status: non_navigational_status
  end

  def auth_options
    { scope: resource_name, recall: "#{controller_path}#new" }
  end
end
