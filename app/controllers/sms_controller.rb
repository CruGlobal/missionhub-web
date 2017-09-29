class SmsController < ApplicationController
  skip_before_action :authenticate_user!, :verify_authenticity_token, :check_valid_subdomain

  SMS_REPLY_TIMEOUT_DAYS = 7

  def mo
    render(xml: blank_response) && return if sms_params[:message].blank?

    if ReceivedSms.where(sms_params).present?
      render(xml: blank_response) && return
    else
      begin
        # try to save the new message
        @received = ReceivedSms.create!(sms_params)
      rescue ActiveRecord::RecordNotUnique
        # the mysql index just saved us from a duplicate message
        render(xml: blank_response) && return
      end
    end
    # Process incoming text
    message = sms_params[:message]

    @sms_session = SmsSession.where(sms_params.slice(:phone_number)).order('updated_at desc')
    # See if this is a sticky session ( prior sms in the past XX minutes )
    unless message.split(' ').first.downcase == 'i'
      @sms_session = @sms_session.active
    end
    @sms_session = @sms_session.first

    phone_number = PhoneNumber.strip_us_country_code(sms_params[:phone_number])

    # Handle STOP and HELP messages

    case message.downcase
    when 'stop'
      if @sms_session
        @sms_session.update_attribute(:interactive, false)
        @organization = @sms_session.sms_keyword.organization
        SmsUnsubscribe.add_to_unsubscribe(phone_number, @organization.id) if @organization.present?
      else
        outbound = Message.last_outbound_text_message(phone_number)
        if outbound.present?
          @organization = outbound.organization
          SmsUnsubscribe.add_to_unsubscribe(phone_number, @organization.id) if @organization
        end
      end

      @msg = I18n.t('sms.sms_unsubscribed_without_org')
      @msg = I18n.t('sms.sms_unsubscribed_with_org', org: @organization) if @organization.present?

      send_message(@msg, sms_params[:phone_number])
      render(xml: @sent_sms.to_twilio) && return
    when 'on'
      unsubscribes = SmsUnsubscribe.where(phone_number: phone_number)

      if unsubscribes.empty?
        @msg = I18n.t('sms.sms_subscribed_without_org')
      else
        if unsubscribes.one?
          org = unsubscribes[0].organization
          @msg = I18n.t('sms.sms_subscribed_with_org', org: org)
          SmsUnsubscribe.remove_from_unsubscribe(phone_number, org.id)
        else
          subscription = SubscriptionSmsSession.create!(phone_number: phone_number, person_id: find_or_create_person.id)
          @msg = I18n.t('sms.sms_subscribed_with_orgs', orgs: subscription.create_choices(unsubscribes))
        end
      end

      send_message(@msg, sms_params[:phone_number])
      render(xml: @sent_sms.to_twilio) && return
    when 'help'
      @msg = I18n.t('sms.sms_help_guide')
      send_message(@msg, sms_params[:phone_number])
      render(xml: @sent_sms.to_twilio) && return
    when ''
      render(xml: blank_response) && return
    end

    # TODO: make sure this doesn't interfere with survey keywords?
    subscription_session = SubscriptionSmsSession.find_by(phone_number: phone_number) # TODO check if active
    if subscription_session
      @msg = subscription_session.subscribe(message)
      send_message(@msg, sms_params[:phone_number])
      render(xml: @sent_sms.to_twilio) && return
    end

    # If it is, check for interactive texting
    if @sms_session && (@sms_session.interactive? || message.split(' ').first.downcase == 'i') && @person = @sms_session.person
      @received.update_attributes(sms_keyword_id: @sms_session.sms_keyword_id, person_id: @sms_session.person_id, sms_session_id: @sms_session.id)
      if keyword = @sms_session.sms_keyword
        survey = keyword.survey
        if !@sms_session.interactive? # they just texted in 'i'
          # We're getting into a sticky session
          survey.organization.add_contact(@person)
          @sms_session.update_attributes(interactive: true)
        else
          # Find the person, save the answer, send the next question
          save_survey_question(keyword.survey, @person, message)
          @person.reload
        end
        @msg = send_next_survey_question(keyword.survey, @person, @sms_session.phone_number)
        unless @msg
          # survey is done. send final message
          @msg = survey.post_survey_message.present? ? survey.post_survey_message : t('contacts.thanks.message')
          # Mark answer_sheet as complete
          @answer_sheet.update_attribute(:completed_at, Time.now)
          @sms_session.update_attributes(ended: true)

          # Manage question rules
          @answer_sheet.save_survey(nil, true)
        end
      else
        @msg = I18n.t('sms.keyword_inactive')
      end
      send_message(@msg, @received.phone_number)

    else
      # We're starting a new sms session
      person = find_or_create_person

      # Look for an active keyword for this message
      first_word = Emojimmy.emoji_to_token(message.downcase).split(' ').first
      keyword = SmsKeyword.where(keyword: first_word).first
      if !keyword || !keyword.active?
        # See if they're responding to an outbound text
        outbound = Message.last_outbound_text_message(phone_number, SMS_REPLY_TIMEOUT_DAYS)
        if outbound
          # Forward this reply on to the sender
          send_message(person.name + ': ' + message, outbound.sender.phone_number).send_sms if outbound.sender
          render(xml: blank_response) && return
        end
        @msg = I18n.t('sms.keyword_inactive')
      elsif !keyword.survey
        @msg = t('sms.no_survey')
      else
        @sms_session = SmsSession.create!(person_id: person.id, sms_keyword_id: keyword.id, phone_number: sms_params[:phone_number])
        @msg = keyword.initial_response.sub(/\{\{\s*link\s*\}\}/, "https://mhub.cc/m/#{Base62.encode(@sms_session.id)}")
        @received.update_attributes(sms_keyword_id: keyword.id, person_id: person.id, sms_session_id: @sms_session.id)
      end
      send_message(@msg, sms_params[:phone_number])
    end
    # render text: @msg.to_s + "\n"
    render xml: @sent_sms.to_twilio
  end

  protected

  def find_or_create_person
    # Try to find a person with this phone number. If we can't, create a new person
    unless person = Person.includes(:phone_numbers).where('phone_numbers.number' => PhoneNumber.strip_us_country_code(sms_params[:phone_number])).first
      # Create a person record for this phone number
      person = Person.new
      person.save(validate: false)
      person.phone_numbers.create!(number: sms_params[:phone_number], location: 'mobile')
    end

    person
  end

  def sent_again?
  end

  def sms_params
    unless @sms_params
      if params['To'] # Twilio
        @sms_params = {}
        @sms_params[:city] = params['FromCity']
        @sms_params[:state] = params['FromState']
        @sms_params[:zip] = params['FromZip']
        @sms_params[:country] = params['FromCountry']
        @sms_params[:phone_number] = params['From'].sub('+', '')
        @sms_params[:shortcode] = params['To']
        @sms_params[:received_at] = Time.now
        @sms_params[:message] = Emojimmy.emoji_to_token(params['Body'].strip.gsub(/\n/, ' ')).mb_chars.to_s
      else
        @sms_params = params.slice(:country)
        @sms_params[:phone_number] = params[:device_address]
        @sms_params[:shortcode] = params[:inbound_address]
        @sms_params[:received_at] = DateTime.strptime(params[:timestamp], '%m/%d/%Y %H:%M:%S')
        @sms_params[:message] = Emojimmy.emoji_to_token(params[:message].strip.gsub(/\n/, ' ')).mb_chars.to_s
      end
    end
    @sms_params
  end

  def send_next_survey_question(survey, person, phone_number)
    question = next_question(survey, person)
    if question
      # finds out whether or not the question was already asked or not yet. If already asked and the question is for email then sent a message that tells email is already taken and user must input another unexisting email
      msg = nil
      begin
        if question.attribute_name == 'email' && SentSms.where(received_sms_id: person.received_sms.reverse[1].id).first.question_id == question.id
          if !person.received_sms.last.message.match(/^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i)
            msg = question.email_invalid
          else
            msg = question.email_should_be_unique_msg
          end
        else
          msg = question.label_for_survey(survey)
        end
        # msg = question.attribute_name == "email" && SentSms.where(received_sms_id: person.received_sms.reverse[1].id).first.question_id == question.id ? question.email_should_be_unique_msg : question.label
      rescue
        msg = question.label_for_survey(survey)
      end
      if question.kind == 'ChoiceField'
        msg = question.label_with_choices(survey)
        separator = / [a-z]\)/
      end

      unless person.first_name.blank? || person.last_name.blank?
        question_no = get_question_no(survey, person)
        msg = "#{question_no} #{msg}"
      end
      @sent_sms = send_message(msg, phone_number, separator, question.id)
    end
    msg
  end

  def save_survey_question(survey, person, answer)
    @answer_sheet = get_answer_sheet(survey, person)
    begin
      case
      when person.first_name.blank?
        person.update_attribute(:first_name, answer)
      when person.last_name.blank?
        person.update_attribute(:last_name, answer)
      else
        question = next_question(survey, person)
        if question
          if question.kind == 'ChoiceField'
            choices = question.choices_by_letter
            # if they typed out a full answer, use that
            answers = answer.gsub(/[^\w]/, '').split(/\s+/).collect { |a| choices.values.detect { |c| c.to_s.downcase == a.to_s.downcase } }.compact
            # if they used letter selections, convert the letter selections to real answers
            answers = answer.gsub(/[^\w]/, '').split(//).collect { |a| choices[a.to_s.downcase] }.compact if answers.empty?

            answers = answers.select { |a| a.to_s.strip != '' }
            # only checkbox fields can have more than one answer
            answer = question.style == 'checkbox' ? answers : answers.first
          end

          if question.attribute_name.present?
            if question.attribute_name == 'email'
              answer = try_to_extract_email_from(answer)
            end
          end

          question.set_response(answer, @answer_sheet)
          p = person.has_similar_person_by_name_and_email?(answer)
          if p # another person with the same first_name, last_name and email has been found
            @answer_sheet.person = @answer_sheet.person.smart_merge(p) # merge person to person with the same first_name, last_name and email
            @answer_sheet.save!
            @answer_sheet.reload
            question.set_response(answer, @answer_sheet)
          end
          begin
            @answer_sheet.person.save(validate: false)
          rescue ActiveRecord::ReadOnlyRecord
            # wtf
          end
        end
      end
    rescue => e
      puts e.backtrace
      # Don't blow up on bad saves
      Rollbar.error(e)
    end
  end

  def get_question_no(survey, person)
    total = survey.questions.count
    answer_sheet = get_answer_sheet(survey, person)
    count = answer_sheet.answers.count
    survey.questions.where('attribute_name IS NOT NULL').each do |in_person_table|
      case in_person_table.attribute_name.strip
      when 'email'
        count += 1 if person.email.present?
      when 'phone_number'
        count += 1 if person.phone_number.present?
      when ''
      else
        count += 1 if check_person_field_presence(person, in_person_table.attribute_name)
      end
    end
    "#{count + 1}/#{total}"
  end

  def check_person_field_presence(person, attribute_name)
    Person.exists?(["id = #{person.id} AND '#{attribute_name}' IS NOT NULL"])
  rescue
    false
  end

  def try_to_extract_email_from(answer)
    answer.match(/\b([a-zA-Z0-9._%+-]+)@([a-zA-Z0-9.-]+?)(\.[a-zA-Z.]*)\b/).to_s
  end

  def next_question(survey, person)
    case
    when person.first_name.blank?
      Question.new(label: 'What is your first name?')
    when person.last_name.blank?
      Question.new(label: 'What is your last name?')
    else
      @answer_sheet = get_answer_sheet(survey, person)
      survey.questions.reload.where(web_only: false, hidden: false).detect { |q| q.responses(@answer_sheet).select(&:present?).blank? }
    end
  end

  def send_message(msg, phone_number, separator = nil, question_id = nil)
    @sent_sms = SentSms.create!(message: msg, recipient: phone_number.strip, received_sms_id: @received.try(:id), separator: separator, question_id: question_id, status: 'sent')
  end

  def blank_response
    '<Response></Response>'
  end
end
