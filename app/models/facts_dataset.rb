class FactsDataset < ApplicationRecord
  STATUSES = %w[draft live archived].freeze

  validates :status, presence: true, inclusion: { in: STATUSES }

  scope :live, -> { where(status: "live") }
  scope :draft, -> { where(status: "draft") }
  scope :archived, -> { where(status: "archived") }

  def live? = status == "live"
  def draft? = status == "draft"
  def archived? = status == "archived"
end
