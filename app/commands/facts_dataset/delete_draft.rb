class FactsDataset::DeleteDraft
  include Mandate

  def call
    FactsDataset.draft.first!.destroy!
  end
end
