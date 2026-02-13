class Action::Create
  include Mandate

  initialize_with :params

  def call
    Action.create!(
      title: params[:title],
      airtable_id: params[:airtable_id],
      enabled: params.fetch(:enabled, true)
    )
  end
end
