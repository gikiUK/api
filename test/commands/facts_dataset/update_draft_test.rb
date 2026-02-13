require "test_helper"

class FactsDataset::UpdateDraftTest < ActiveSupport::TestCase
  test "updates draft data and test_cases" do
    create(:facts_dataset, :live)
    draft = create(:facts_dataset, :draft)

    new_data = { "facts" => { "has_vehicles" => { "type" => "boolean_state" } } }
    new_test_cases = [ { "name" => "Test case 1" } ]

    FactsDataset::UpdateDraft.(new_data, new_test_cases)

    assert_equal new_data, draft.reload.data
    assert_equal new_test_cases, draft.reload.test_cases
  end

  test "calls validate on the draft" do
    create(:facts_dataset, :live)
    draft = create(:facts_dataset, :draft)

    FactsDataset::Validate.expects(:call).with(draft.data, draft.test_cases).returns(true)

    FactsDataset::UpdateDraft.(draft.data, draft.test_cases)
  end

  test "locks the draft row for update" do
    create(:facts_dataset, :live)
    draft = create(:facts_dataset, :draft)

    draft.expects(:with_lock).yields
    FactsDataset.expects(:draft).returns(draft)

    FactsDataset::UpdateDraft.({}, [])
  end

  test "raises when no draft exists" do
    assert_raises(ActiveRecord::RecordNotFound) do
      FactsDataset::UpdateDraft.({}, [])
    end
  end
end
