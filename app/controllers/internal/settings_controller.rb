class Internal::SettingsController < Internal::BaseController
  def show
    render json: { settings: SerializeSettings.(current_user) }
  end

  def locale
    User::UpdateLocale.(current_user, params[:value])
    render json: { settings: SerializeSettings.(current_user) }
  rescue ActiveRecord::RecordInvalid => e
    render_settings_error("Locale update failed", e)
  end

  private
  def render_settings_error(message, exception)
    render json: {
      error: {
        type: :validation_error,
        message:,
        errors: exception.record.errors.as_json
      }
    }, status: :unprocessable_entity
  end
end
