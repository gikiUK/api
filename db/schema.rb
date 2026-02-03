# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_02_02_165146) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "user_data", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_bounce_reason"
    t.datetime "email_bounced_at"
    t.datetime "email_complaint_at"
    t.string "email_complaint_type"
    t.datetime "last_email_opened_at"
    t.boolean "notifications_enabled", default: true, null: false
    t.datetime "otp_enabled_at"
    t.string "otp_secret"
    t.boolean "receive_newsletters", default: true, null: false
    t.string "timezone"
    t.string "unsubscribe_token", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["unsubscribe_token"], name: "index_user_data_on_unsubscribe_token", unique: true
    t.index ["user_id"], name: "index_user_data_on_user_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "unconfirmed_email"
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "user_data", "users"
end
