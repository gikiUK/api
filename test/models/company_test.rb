require "test_helper"

class CompanyTest < ActiveSupport::TestCase
  test "creates company with valid name" do
    company = create(:company)
    assert company.persisted?
  end

  test "requires name" do
    company = build(:company, name: nil)
    assert_not company.valid?
    assert_includes company.errors[:name], "can't be blank"
  end

  test "has many company_memberships" do
    company = create(:company)
    user1 = create(:user)
    user2 = create(:user)

    company.company_memberships.create!(user: user1)
    company.company_memberships.create!(user: user2)

    assert_equal 2, company.company_memberships.count
  end

  test "has many users through company_memberships" do
    company = create(:company)
    user1 = create(:user)
    user2 = create(:user)

    company.company_memberships.create!(user: user1)
    company.company_memberships.create!(user: user2)

    assert_equal 2, company.users.count
    assert_includes company.users, user1
    assert_includes company.users, user2
  end

  test "company_memberships are destroyed when company is destroyed" do
    company = create(:company)
    user = create(:user)
    membership = company.company_memberships.create!(user: user)
    membership_id = membership.id

    company.destroy!

    refute CompanyMembership.exists?(membership_id)
  end
end
