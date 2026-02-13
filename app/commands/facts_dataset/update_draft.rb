class FactsDataset::UpdateDraft
  include Mandate

  initialize_with :data, :test_cases

  def call
    draft = FactsDataset.draft
    draft.with_lock do
      FactsDataset::Validate.(data, test_cases)
      draft.update!(data:, test_cases:)
    end
  end
end
