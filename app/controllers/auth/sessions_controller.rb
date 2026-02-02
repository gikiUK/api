class Auth::SessionsController < Devise::SessionsController
  respond_to :json

  def create
    self.resource = warden.authenticate(auth_options)

    if resource.blank?
      return render json: {
        error: {
          type: "unauthorized",
          message: "Invalid email or password"
        }
      }, status: :unauthorized
    end

    sign_in(resource_name, resource)
    render json: { status: "success" }, status: :ok
  end

  private
  def respond_to_on_destroy(non_navigational_status: :no_content)
    render json: {}, status: non_navigational_status
  end

  def auth_options
    { scope: resource_name, recall: "#{controller_path}#new" }
  end
end
