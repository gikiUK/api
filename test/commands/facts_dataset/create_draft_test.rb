require "test_helper"

class FactsDataset::CreateDraftTest < ActiveSupport::TestCase
  test "creates draft by copying live dataset" do
    live = create(:facts_dataset, :live, :with_data, :with_test_cases)

    draft = FactsDataset::CreateDraft.()

    assert draft.persisted?
    assert_equal "draft", draft.status
    assert_equal live.data, draft.data
    assert_equal live.test_cases, draft.test_cases
  end

  test "raises when no live dataset exists" do
    assert_raises(ActiveRecord::RecordNotFound) do
      FactsDataset::CreateDraft.()
    end
  end

  test "raises when draft already exists" do
    create(:facts_dataset, :live)
    create(:facts_dataset, :draft)

    assert_raises(ActiveRecord::RecordNotUnique) do
      FactsDataset::CreateDraft.()
    end
  end
end
