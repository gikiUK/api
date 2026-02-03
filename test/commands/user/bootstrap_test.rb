require "test_helper"

class User::BootstrapTest < ActiveSupport::TestCase
  test "enqueues welcome email" do
    user = create(:user)

    assert_enqueued_with(
      job: ActionMailer::MailDeliveryJob,
      args: [ "AccountMailer", "welcome", "deliver_now", { args: [ user ] } ]
    ) do
      User::Bootstrap.(user)
    end
  end

  test "works with newly created user" do
    user = build(:user)
    user.save!

    assert_enqueued_jobs 1, only: ActionMailer::MailDeliveryJob do
      User::Bootstrap.(user)
    end
  end
end
