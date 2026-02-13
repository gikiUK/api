class FactsDataset::PromoteDraftToLive
  include Mandate

  def call
    draft = FactsDataset.draft.first!
    FactsDataset::Validate.(draft)

    FactsDataset.transaction do
      FactsDataset.live.first!.update!(status: "archived")
      draft.update!(status: "live")
    end
  end
end
