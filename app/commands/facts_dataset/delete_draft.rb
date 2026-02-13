class FactsDataset::DeleteDraft
  include Mandate

  def call
    FactsDataset.draft.destroy!
  end
end
