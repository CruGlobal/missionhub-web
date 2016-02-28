class ContactsMailer < ActionMailer::Base
  default from: "\"#{ENV['SITE_TITLE']}\" <support@missionhub.com>"

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.contacts_mailer.reminder.subject
  #
  def reminder(to, _from, subject, content)
    @content = content

    mail to: to, subject: subject
  end
end
