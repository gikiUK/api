class SerializeAdminActions
  include Mandate

  initialize_with :actions

  def call
    actions.map { |action| SerializeAdminAction.(action) }
  end
end
