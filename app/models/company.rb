class Company < ApplicationRecord
  has_many :company_memberships, dependent: :destroy
  has_many :users, through: :company_memberships

  validates :name, presence: true
end
