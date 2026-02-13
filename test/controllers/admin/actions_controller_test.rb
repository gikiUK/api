require "test_helper"

class Admin::ActionsControllerTest < ApplicationControllerTest
  setup do
    @admin = create(:user, :admin)
    sign_in_user(@admin)
  end

  # Auth guards
  guard_admin! :admin_actions_path, method: :get
  guard_admin! :admin_actions_path, method: :post
  guard_admin! :admin_action_path, args: [ 1 ], method: :get
  guard_admin! :admin_action_path, args: [ 1 ], method: :patch

  # GET /admin/actions

  test "GET index returns all actions" do
    action1 = create(:action, title: "Install solar panels")
    action2 = create(:action, title: "Reduce business travel")

    get admin_actions_path, as: :json

    assert_response :success
    assert_json_response({
      actions: SerializeAdminActions.([ action1, action2 ])
    })
  end

  test "GET index returns empty array when no actions exist" do
    get admin_actions_path, as: :json

    assert_response :success
    assert_json_response({ actions: [] })
  end

  # GET /admin/actions/:id

  test "GET show returns the action" do
    action = create(:action)

    get admin_action_path(action), as: :json

    assert_response :success
    assert_json_response({
      action: SerializeAdminAction.(action)
    })
  end

  test "GET show returns 404 when action not found" do
    get admin_action_path(999_999), as: :json

    assert_json_error(:not_found, error_type: :action_not_found)
  end

  # POST /admin/actions

  test "POST create creates a new action" do
    post admin_actions_path, params: { title: "Switch to renewable energy" }, as: :json

    assert_response :created
    action = Action.last
    assert_equal "Switch to renewable energy", action.title
    assert action.enabled
    assert_json_response({
      action: SerializeAdminAction.(action)
    })
  end

  test "POST create returns 422 when title is missing" do
    post admin_actions_path, params: { title: "" }, as: :json

    assert_json_error(:unprocessable_entity, error_type: :validation_error, errors: { title: [ "can't be blank" ] })
  end

  # PATCH /admin/actions/:id

  test "PATCH update updates the action" do
    action = create(:action, title: "Old title")

    patch admin_action_path(action), params: { title: "New title" }, as: :json

    assert_response :success
    assert_equal "New title", action.reload.title
    assert_json_response({
      action: SerializeAdminAction.(action.reload)
    })
  end

  test "PATCH update can disable an action" do
    action = create(:action)

    patch admin_action_path(action), params: { enabled: false }, as: :json

    assert_response :success
    assert_not action.reload.enabled
  end

  test "PATCH update returns 404 when action not found" do
    patch admin_action_path(999_999), params: { title: "New title" }, as: :json

    assert_json_error(:not_found, error_type: :action_not_found)
  end

  test "PATCH update returns 422 when title is blank" do
    action = create(:action)

    patch admin_action_path(action), params: { title: "" }, as: :json

    assert_json_error(:unprocessable_entity, error_type: :validation_error, errors: { title: [ "can't be blank" ] })
  end
end
