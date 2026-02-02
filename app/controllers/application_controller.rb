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
end
