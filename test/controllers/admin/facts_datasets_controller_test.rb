require "test_helper"

class Admin::FactsDatasetsControllerTest < ApplicationControllerTest
  setup do
    @admin = create(:user, :admin)
    sign_in_user(@admin)
  end

  # Auth guards
  guard_admin! :admin_facts_datasets_live_path, method: :get
  guard_admin! :admin_facts_datasets_draft_path, method: :get
  guard_admin! :admin_facts_datasets_draft_path, method: :post
  guard_admin! :admin_facts_datasets_draft_path, method: :patch
  guard_admin! :admin_facts_datasets_draft_path, method: :delete
  guard_admin! :admin_facts_datasets_draft_publish_path, method: :post

  # GET /admin/facts_datasets/live

  test "GET live returns the live dataset" do
    dataset = create(:facts_dataset, :live, :with_data)

    get admin_facts_datasets_live_path, as: :json

    assert_response :success
    assert_json_response({
      facts_dataset: SerializeAdminFactsDataset.(dataset)
    })
  end

  test "GET live returns 404 when no live dataset exists" do
    get admin_facts_datasets_live_path, as: :json

    assert_json_error(:not_found, error_type: :facts_dataset_not_found)
  end

  # GET /admin/facts_datasets/draft

  test "GET draft returns the draft dataset" do
    create(:facts_dataset, :live)
    dataset = create(:facts_dataset, :draft, :with_data)

    get admin_facts_datasets_draft_path, as: :json

    assert_response :success
    assert_json_response({
      facts_dataset: SerializeAdminFactsDataset.(dataset)
    })
  end

  test "GET draft returns 404 when no draft exists" do
    get admin_facts_datasets_draft_path, as: :json

    assert_json_error(:not_found, error_type: :facts_dataset_not_found)
  end

  # POST /admin/facts_datasets/draft

  test "POST draft creates a draft from the live dataset" do
    create(:facts_dataset, :live, :with_data, :with_test_cases)

    post admin_facts_datasets_draft_path, as: :json

    assert_response :created
    draft = FactsDataset.draft
    assert_json_response({
      facts_dataset: SerializeAdminFactsDataset.(draft)
    })
  end

  test "POST draft returns 404 when no live dataset exists" do
    post admin_facts_datasets_draft_path, as: :json

    assert_json_error(:not_found, error_type: :facts_dataset_not_found)
  end

  test "POST draft returns existing draft when one already exists" do
    create(:facts_dataset, :live)
    existing_draft = create(:facts_dataset, :draft)

    post admin_facts_datasets_draft_path, as: :json

    assert_response :created
    assert_json_response({
      facts_dataset: SerializeAdminFactsDataset.(existing_draft)
    })
  end

  # PATCH /admin/facts_datasets/draft

  test "PATCH draft updates the draft blob" do
    create(:facts_dataset, :live)
    create(:facts_dataset, :draft)

    new_data = { facts: { has_vehicles: { type: "boolean_state", enabled: true } } }
    new_test_cases = [ { name: "Test 1" } ]

    patch admin_facts_datasets_draft_path, params: { data: new_data, test_cases: new_test_cases }, as: :json

    assert_response :success
    draft = FactsDataset.draft
    assert_json_response({
      facts_dataset: SerializeAdminFactsDataset.(draft)
    })
  end

  test "PATCH draft returns 404 when no draft exists" do
    patch admin_facts_datasets_draft_path, params: { data: {}, test_cases: [] }, as: :json

    assert_json_error(:not_found, error_type: :facts_dataset_not_found)
  end

  # DELETE /admin/facts_datasets/draft

  test "DELETE draft deletes the draft" do
    create(:facts_dataset, :live)
    create(:facts_dataset, :draft)

    delete admin_facts_datasets_draft_path, as: :json

    assert_response :success
    assert_raises(ActiveRecord::RecordNotFound) { FactsDataset.draft }
  end

  test "DELETE draft returns 404 when no draft exists" do
    delete admin_facts_datasets_draft_path, as: :json

    assert_json_error(:not_found, error_type: :facts_dataset_not_found)
  end

  # POST /admin/facts_datasets/draft/publish

  test "POST publish promotes draft to live" do
    old_live = create(:facts_dataset, :live)
    draft = create(:facts_dataset, :draft, :with_data)

    post admin_facts_datasets_draft_publish_path, as: :json

    assert_response :success
    assert old_live.reload.archived?
    assert draft.reload.live?
    assert_json_response({
      facts_dataset: SerializeAdminFactsDataset.(draft.reload)
    })
  end

  test "POST publish returns 404 when no draft exists" do
    create(:facts_dataset, :live)

    post admin_facts_datasets_draft_publish_path, as: :json

    assert_json_error(:not_found, error_type: :facts_dataset_not_found)
  end

  test "POST publish returns 404 when no live dataset exists" do
    create(:facts_dataset, :draft)

    post admin_facts_datasets_draft_publish_path, as: :json

    assert_json_error(:not_found, error_type: :facts_dataset_not_found)
  end
end
