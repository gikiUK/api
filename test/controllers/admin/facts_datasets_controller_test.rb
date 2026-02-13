require "test_helper"

class Admin::FactsDatasetsControllerTest < ApplicationControllerTest
  setup do
    @admin = create(:user, :admin)
    sign_in_user(@admin)
  end

  # Auth guards
  guard_admin! :admin_facts_datasets_live_path, method: :get

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
end
