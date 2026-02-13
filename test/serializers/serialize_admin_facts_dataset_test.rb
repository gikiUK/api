require "test_helper"

class SerializeAdminFactsDatasetTest < ActiveSupport::TestCase
  test "serializes facts dataset" do
    dataset = create(:facts_dataset, :with_data, :with_test_cases)

    result = SerializeAdminFactsDataset.(dataset)

    expected = {
        id: dataset.id,
        status: dataset.status,
        data: dataset.data,
        test_cases: dataset.test_cases
      }
    assert_equal expected, result
  end
end
