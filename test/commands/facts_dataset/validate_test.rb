require "test_helper"

class FactsDataset::ValidateTest < ActiveSupport::TestCase
  test "returns true" do
    dataset = create(:facts_dataset)

    assert FactsDataset::Validate.(dataset)
  end
end
