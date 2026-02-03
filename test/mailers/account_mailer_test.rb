require "test_helper"

class AccountMailerTest < ActionMailer::TestCase
  test "welcome email renders correctly" do
    user = create(:user)
    mail = AccountMailer.welcome(user)

    assert_equal "Welcome to Giki!", mail.subject
    assert_equal [ Giki.config.mail_from_email ], mail.from
    assert_equal [ user.email ], mail.to

    assert_match "Welcome!", mail.html_part.body.to_s
    assert_match "environmental impact", mail.html_part.body.to_s
    assert_match "Get Started", mail.html_part.body.to_s
    assert_match "#{Giki.config.frontend_base_url}/login", mail.html_part.body.to_s

    assert_match "Welcome!", mail.text_part.body.to_s
    assert_match "environmental impact", mail.text_part.body.to_s
  end

  test "welcome email compiles MJML to responsive HTML" do
    user = create(:user)
    mail = AccountMailer.welcome(user)

    html_body = mail.html_part.body.to_s

    assert_match(/<table/, html_body)
    refute_match(/<mj-/, html_body)
    assert_match(/<!doctype html>/i, html_body)
    assert_match(/viewport/, html_body)
  end

  test "welcome email includes both HTML and text parts" do
    user = create(:user)
    mail = AccountMailer.welcome(user)

    assert mail.html_part.present?
    assert mail.text_part.present?
    assert_equal "text/html", mail.html_part.content_type.split(";").first
    assert_equal "text/plain", mail.text_part.content_type.split(";").first
  end

  test "welcome email includes login URL in button" do
    user = create(:user)
    mail = AccountMailer.welcome(user)
    expected_url = "#{Giki.config.frontend_base_url}/login"

    assert_match expected_url, mail.html_part.body.to_s
    assert_match expected_url, mail.text_part.body.to_s
  end

  test "welcome email does not include unsubscribe headers" do
    user = create(:user)
    mail = AccountMailer.welcome(user)

    assert_nil mail.header['List-Unsubscribe']
    assert_nil mail.header['List-Unsubscribe-Post']
  end
end
