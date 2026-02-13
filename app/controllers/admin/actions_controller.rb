class Admin::ActionsController < Admin::BaseController
  before_action :use_action!, only: [ :show, :update ]

  def index
    actions = Action.all.order(:id)
    render json: { actions: SerializeAdminActions.(actions) }
  end

  def show
    render json: { action: SerializeAdminAction.(@action) }
  end

  def create
    action = Action::Create.(action_params)
    render json: { action: SerializeAdminAction.(action) }, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render_422(:validation_error, errors: e.record.errors.messages)
  end

  def update
    action = Action::Update.(@action, action_params)
    render json: { action: SerializeAdminAction.(action) }
  rescue ActiveRecord::RecordInvalid => e
    render_422(:validation_error, errors: e.record.errors.messages)
  end

  private

  def use_action!
    @action = Action.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404(:action_not_found)
  end

  def action_params = params.permit(:title, :airtable_id, :enabled)
end
