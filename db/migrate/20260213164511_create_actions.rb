class CreateActions < ActiveRecord::Migration[8.1]
  def change
    create_table :actions do |t|
      t.string :airtable_id
      t.string :title, null: false
      t.boolean :enabled, null: false, default: true
      t.timestamps

      t.index :airtable_id, unique: true
    end
  end
end
