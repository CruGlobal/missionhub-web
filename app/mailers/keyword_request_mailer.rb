class KeywordRequestMailer < ActionMailer::Base
  default from: "\"#{ENV['SITE_TITLE']} Support\" <support@missionhub.com>"
  layout 'email'

  def new_keyword_request(keyword_id)
    @keyword = SmsKeyword.find(keyword_id)
    mail(to: 'support@missionhub.com',
         subject: 'New sms keyword request')
  end

  def notify_user(keyword_id)
    @keyword = SmsKeyword.find(keyword_id)
    @organization = @keyword.organization
    mail(to: @keyword.user.person.email, subject: "Keyword '#{@keyword}' was approved!")
  end

  def notify_user_of_denial(keyword_id)
    @keyword = SmsKeyword.find(keyword_id)
    mail(to: @keyword.user.person.email, subject: "Keyword '#{@keyword}' was rejected.")
  end
end
