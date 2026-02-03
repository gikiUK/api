class CreateCompanyMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :company_memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :company, null: false, foreign_key: true

      t.timestamps
    end

    add_index :company_memberships, [:user_id, :company_id], unique: true
  end
end
