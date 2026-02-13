class FactsDataset::CreateDraft
  include Mandate

  def call
    FactsDataset.create!(
      status: "draft",
      data: live_dataset.data,
      test_cases: live_dataset.test_cases
    )
  end

  private

  memoize
  def live_dataset = FactsDataset.live.first!
end
