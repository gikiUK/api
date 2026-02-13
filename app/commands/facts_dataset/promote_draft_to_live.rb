class FactsDataset::PromoteDraftToLive
  include Mandate

  def call
    draft = FactsDataset.draft
    FactsDataset::Validate.(draft.data, draft.test_cases)

    FactsDataset.transaction do
      FactsDataset.live.update!(status: "archived")
      draft.update!(status: "live")
    end
  end
end
