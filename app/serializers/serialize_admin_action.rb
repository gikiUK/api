class SerializeAdminAction
  include Mandate

  initialize_with :action

  def call
    {
      id: action.id,
      title: action.title,
      enabled: action.enabled
    }
  end
end
