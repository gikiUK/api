require "test_helper"

class CompanyMembershipTest < ActiveSupport::TestCase
  test "creates membership with valid user and company" do
    membership = create(:company_membership)
    assert membership.persisted?
  end

  test "requires user" do
    membership = build(:company_membership, user: nil)
    assert_not membership.valid?
    assert_includes membership.errors[:user], "must exist"
  end

  test "requires company" do
    membership = build(:company_membership, company: nil)
    assert_not membership.valid?
    assert_includes membership.errors[:company], "must exist"
  end

  test "prevents duplicate user-company combination" do
    user = create(:user)
    company = create(:company)

    create(:company_membership, user: user, company: company)

    duplicate = build(:company_membership, user: user, company: company)
    assert_not duplicate.valid?
  end

  test "allows same user in different companies" do
    user = create(:user)
    company1 = create(:company)
    company2 = create(:company)

    membership1 = create(:company_membership, user: user, company: company1)
    membership2 = create(:company_membership, user: user, company: company2)

    assert membership1.persisted?
    assert membership2.persisted?
  end

  test "allows same company with different users" do
    user1 = create(:user)
    user2 = create(:user)
    company = create(:company)

    membership1 = create(:company_membership, user: user1, company: company)
    membership2 = create(:company_membership, user: user2, company: company)

    assert membership1.persisted?
    assert membership2.persisted?
  end
end
