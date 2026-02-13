class Action < ApplicationRecord
  validates :title, presence: true
  validates :airtable_id, uniqueness: true, allow_nil: true
end
