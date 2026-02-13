class FactsDataset < ApplicationRecord
  STATUSES = %w[draft live archived].freeze

  validates :status, presence: true, inclusion: { in: STATUSES }

  def self.live = where(status: "live").first!
  def self.draft = where(status: "draft").first!

  def live? = status == "live"
  def draft? = status == "draft"
  def archived? = status == "archived"
end
