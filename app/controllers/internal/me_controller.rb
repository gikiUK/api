class Internal::MeController < Internal::BaseController
  def show
    render json: SerializeUser.(current_user)
  end
end
