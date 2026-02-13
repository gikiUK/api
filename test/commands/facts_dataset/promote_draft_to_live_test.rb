require "test_helper"

class FactsDataset::PromoteDraftToLiveTest < ActiveSupport::TestCase
  test "promotes draft to live and archives old live" do
    old_live = create(:facts_dataset, :live)
    draft = create(:facts_dataset, :draft, :with_data)

    FactsDataset::PromoteDraftToLive.()

    assert old_live.reload.archived?
    assert draft.reload.live?
  end

  test "calls validate on the draft" do
    create(:facts_dataset, :live)
    draft = create(:facts_dataset, :draft)

    FactsDataset::Validate.expects(:call).with(draft.data, draft.test_cases).returns(true)

    FactsDataset::PromoteDraftToLive.()
  end

  test "raises when no draft exists" do
    create(:facts_dataset, :live)

    assert_raises(ActiveRecord::RecordNotFound) do
      FactsDataset::PromoteDraftToLive.()
    end
  end

  test "raises when no live dataset exists" do
    create(:facts_dataset, :draft)

    assert_raises(ActiveRecord::RecordNotFound) do
      FactsDataset::PromoteDraftToLive.()
    end
  end
end
