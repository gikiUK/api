class Auth::SessionsController < Devise::SessionsController
  respond_to :json

  def create
    self.resource = warden.authenticate!(auth_options)

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
