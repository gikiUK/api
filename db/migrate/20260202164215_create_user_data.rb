class CreateUserData < ActiveRecord::Migration[8.1]
  def change
    create_table :user_data do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }

      # Timezone
      t.string :timezone

      # Email unsubscribe token (required, generated on create)
      t.string :unsubscribe_token, null: false

      # Email preferences
      t.boolean :notifications_enabled, default: true, null: false
      t.boolean :receive_newsletters, default: true, null: false

      # Email tracking
      t.datetime :email_bounced_at
      t.string :email_bounce_reason
      t.datetime :email_complaint_at
      t.string :email_complaint_type
      t.datetime :last_email_opened_at

      # Two-Factor Authentication
      t.string :otp_secret
      t.datetime :otp_enabled_at

      t.timestamps
    end

    add_index :user_data, :unsubscribe_token, unique: true
  end
end
