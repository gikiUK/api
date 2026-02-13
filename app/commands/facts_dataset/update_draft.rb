class FactsDataset::UpdateDraft
  include Mandate

  initialize_with :data, :test_cases

  def call
    FactsDataset.transaction do
      draft = FactsDataset.lock.find_by!(status: "draft")
      FactsDataset::Validate.(draft)
      draft.update!(data:, test_cases:)
      draft
    end
  end
end
