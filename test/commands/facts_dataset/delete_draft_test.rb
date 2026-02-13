require "test_helper"

class FactsDataset::DeleteDraftTest < ActiveSupport::TestCase
  test "deletes the draft dataset" do
    create(:facts_dataset, :live)
    create(:facts_dataset, :draft)

    FactsDataset::DeleteDraft.()

    assert_raises(ActiveRecord::RecordNotFound) { FactsDataset.draft }
  end

  test "does not affect live dataset" do
    live = create(:facts_dataset, :live)
    create(:facts_dataset, :draft)

    FactsDataset::DeleteDraft.()

    assert live.reload.live?
  end

  test "raises when no draft exists" do
    assert_raises(ActiveRecord::RecordNotFound) do
      FactsDataset::DeleteDraft.()
    end
  end
end
