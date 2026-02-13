class Admin::FactsDatasetsController < Admin::BaseController
  def live
    dataset = FactsDataset.live
    render json: { facts_dataset: SerializeAdminFactsDataset.(dataset) }
  rescue ActiveRecord::RecordNotFound
    render_404(:facts_dataset_not_found)
  end

  def draft
    dataset = FactsDataset.draft
    render json: { facts_dataset: SerializeAdminFactsDataset.(dataset) }
  rescue ActiveRecord::RecordNotFound
    render_404(:facts_dataset_not_found)
  end

  def create_draft
    dataset = FactsDataset::CreateDraft.()
    render json: { facts_dataset: SerializeAdminFactsDataset.(dataset) }, status: :created
  rescue ActiveRecord::RecordNotFound
    render_404(:facts_dataset_not_found)
  end

  def update_draft
    FactsDataset::UpdateDraft.(params[:data], params[:test_cases])
    render json: { facts_dataset: SerializeAdminFactsDataset.(FactsDataset.draft) }
  rescue ActiveRecord::RecordNotFound
    render_404(:facts_dataset_not_found)
  end

  def delete_draft
    FactsDataset::DeleteDraft.()
    render json: {}, status: :ok
  rescue ActiveRecord::RecordNotFound
    render_404(:facts_dataset_not_found)
  end

  def publish_draft
    FactsDataset::PromoteDraftToLive.()
    dataset = FactsDataset.live
    render json: { facts_dataset: SerializeAdminFactsDataset.(dataset) }
  rescue ActiveRecord::RecordNotFound
    render_404(:facts_dataset_not_found)
  end
end
