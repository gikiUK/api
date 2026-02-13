class Action::Update
  include Mandate

  initialize_with :action, :params

  def call
    action.update!(params.slice(:title, :airtable_id, :enabled))
    action
  end
end
