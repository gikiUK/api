class SerializeAdminFactsDataset
  include Mandate

  initialize_with :dataset

  def call
    {
      id: dataset.id,
      status: dataset.status,
      data: dataset.data,
      test_cases: dataset.test_cases
    }
  end
end
