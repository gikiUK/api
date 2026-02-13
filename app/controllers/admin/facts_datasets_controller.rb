class Admin::FactsDatasetsController < Admin::BaseController
  def live
    dataset = FactsDataset.live.first!
    render json: { facts_dataset: SerializeAdminFactsDataset.(dataset) }
  rescue ActiveRecord::RecordNotFound
    render_404(:facts_dataset_not_found)
  end
end
