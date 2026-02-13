class CreateFactsDatasets < ActiveRecord::Migration[8.1]
  def change
    create_table :facts_datasets do |t|
      t.string :status, null: false
      t.jsonb :data, null: false, default: {}
      t.jsonb :test_cases, null: false, default: []
      t.timestamps
    end

    # Only one live dataset at a time
    add_index :facts_datasets, :status, unique: true, where: "status = 'live'", name: "index_facts_datasets_unique_live"
    # Only one draft at a time
    add_index :facts_datasets, :status, unique: true, where: "status = 'draft'", name: "index_facts_datasets_unique_draft"
  end
end
