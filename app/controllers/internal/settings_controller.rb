class Internal::SettingsController < Internal::BaseController
  def show
    render json: { settings: SerializeSettings.(current_user) }
  end

  def locale
    User::UpdateLocale.(current_user, params[:value])
    render json: { settings: SerializeSettings.(current_user) }
  rescue ActiveRecord::RecordInvalid => e
    render_422(:locale_update_failed, errors: e.record.errors.as_json)
  end
end
