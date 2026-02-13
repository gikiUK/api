require "test_helper"

class FactsDatasetTest < ActiveSupport::TestCase
  test "creates facts dataset with valid attributes" do
    dataset = create(:facts_dataset)
    assert dataset.persisted?
  end

  test "requires status" do
    dataset = build(:facts_dataset, status: nil)
    assert_not dataset.valid?
    assert_includes dataset.errors[:status], "can't be blank"
  end

  test "validates status is one of allowed values" do
    dataset = build(:facts_dataset, status: "invalid")
    assert_not dataset.valid?
    assert_includes dataset.errors[:status], "is not included in the list"
  end

  %w[draft live archived].each do |status|
    test "allows #{status} status" do
      dataset = create(:facts_dataset, status.to_sym)
      assert dataset.persisted?
      assert_equal status, dataset.status
    end
  end

  test "data defaults to empty hash" do
    dataset = FactsDataset.new(status: "live")
    assert_equal({}, dataset.data)
  end

  test "test_cases defaults to empty array" do
    dataset = FactsDataset.new(status: "live")
    assert_equal([], dataset.test_cases)
  end

  test "stores complex jsonb data" do
    dataset = create(:facts_dataset, :with_data)

    assert dataset.data["facts"].is_a?(Hash)
    assert dataset.data["questions"].is_a?(Array)
    assert dataset.data["rules"].is_a?(Array)
    assert dataset.data["constants"].is_a?(Hash)
    assert dataset.data["action_conditions"].is_a?(Hash)
  end

  test "stores test case objects" do
    dataset = create(:facts_dataset, :with_test_cases)

    assert_equal 1, dataset.test_cases.length
    assert_equal "Small advertising agency", dataset.test_cases.first["name"]
  end

  test "live class method returns the live dataset" do
    live = create(:facts_dataset, :live)
    create(:facts_dataset, :draft)
    create(:facts_dataset, :archived)

    assert_equal live, FactsDataset.live
  end

  test "live class method raises when no live dataset exists" do
    assert_raises(ActiveRecord::RecordNotFound) { FactsDataset.live }
  end

  test "draft class method returns the draft dataset" do
    create(:facts_dataset, :live)
    draft = create(:facts_dataset, :draft)
    create(:facts_dataset, :archived)

    assert_equal draft, FactsDataset.draft
  end

  test "draft class method raises when no draft exists" do
    assert_raises(ActiveRecord::RecordNotFound) { FactsDataset.draft }
  end

  test "live? returns true only for live dataset" do
    assert create(:facts_dataset, :live).live?
    refute create(:facts_dataset, :draft).live?
  end

  test "draft? returns true only for draft dataset" do
    assert create(:facts_dataset, :draft).draft?
    refute create(:facts_dataset, :live).draft?
  end

  test "archived? returns true only for archived dataset" do
    assert create(:facts_dataset, :archived).archived?
    refute create(:facts_dataset, :live).archived?
  end

  test "prevents multiple live datasets" do
    create(:facts_dataset, :live)

    assert_raises(ActiveRecord::RecordNotUnique) do
      create(:facts_dataset, :live)
    end
  end

  test "prevents multiple draft datasets" do
    create(:facts_dataset, :draft)

    assert_raises(ActiveRecord::RecordNotUnique) do
      create(:facts_dataset, :draft)
    end
  end

  test "allows multiple archived datasets" do
    dataset1 = create(:facts_dataset, :archived)
    dataset2 = create(:facts_dataset, :archived)

    assert dataset1.persisted?
    assert dataset2.persisted?
  end
end
