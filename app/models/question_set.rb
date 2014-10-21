# QuestionSet
# represents a group of elements, with their answers
class QuestionSet

  attr_reader :elements

  # associate answers from database with a set of elements
  def initialize(elements, answer_sheet)
    @elements = elements
    @answer_sheet = answer_sheet

    @questions = elements.select { |e| e.question? }

    # answers = @answer_sheet.answers_by_question

    @questions.each do |question|
      question.answers = question.responses(answer_sheet) #answers[question.id]
    end
    @questions
  end

  # update with responses from form
  def post(params, answer_sheet)
    questions_indexed = @questions.index_by {|q| q.id}
    # loop over form values
    params ||= {}
    params.each do |question_id, response|
      if response.to_s.strip.present? # Don't save blanks
        next if questions_indexed[question_id.to_i].nil? # the rare case where a question was removed after the app was opened.
        # update each question with the posted response
        questions_indexed[question_id.to_i].set_response(posted_values(response), answer_sheet)
      else
        answer = Answer.find_by_answer_sheet_id_and_question_id(answer_sheet.id,question_id)
        if answer.present?
          answer.destroy
        end
      end
    end
  end

  def any_questions?
    @questions.length > 0
  end

  def save
    AnswerSheet.transaction do
      @questions.each do |question|
        question.save_response(@answer_sheet, question)
        answer = @answer_sheet.answers.find_by_question_id(question.id)
        question_rules = SurveyElement.find_by_element_id(question.id).question_rules

        if answer.present? && question_rules.present?
          question_rules.each do |question_rule|
            triggers = question_rule.trigger_keywords
            if triggers.present?
              trigger_words = triggers.split(',').try(:compact)
              if trigger_words.map{|x| x.downcase.strip}.include?(answer.value.downcase.strip)
                code = question_rule.rule.rule_code

                case code
                when 'AUTONOTIFY'
                  # Do the process
                  leaders = Person.find(question_rule.extra_parameters['leaders'])
                  recipients = leaders.collect{|p| "#{p.name} <#{p.email}>"}.join(", ")
                  PeopleMailer.delay.notify_on_survey_answer(recipients, question_rule.id, keyword_found, answer.id)
                when 'AUTOASSIGN'
                  # Do the process
                  person =  @answer_sheet.person

                  organization = @answer_sheet.survey.organization
                  extra_parameters = question_rule.extra_parameters

                  type = extra_parameters["type"]
                  extra_id = extra_parameters["id"]

                  if type.present?
                    case type.downcase
                    when 'leader'
                      person.assign_to_leader(organization, extra_id)
                    when 'ministry'
                      ministry = person.all_organization_and_children.find_by_id(extra_id)
                      ministry.add_contact(person) if ministry.present?
                    when 'group'
                      group = organization.groups.find_by_id(extra_id)
                      person.add_to_group(organization, group) if group.present?
                    when 'label'
                      label = organization.labels.find_by_id(extra_id)
                      person.add_to_label(organization, label) if label.present?
                    end
                  else
                    # To consider all the old data in the database
                    leaders = extra_parameters["leaders"]
                    if leaders.present?
                      leaders.each do |leader_id|
                        person.assign_to_leader(organization, leader_id)
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end

  private

  # convert posted response to a question into Array of values
  def posted_values(param)

    if param.kind_of?(Hash) && param.has_key?('year') && param.has_key?('month')
      year = param['year']
      month = param['month']
      if month.blank? or year.blank?
        values = ''
      else
        values = [Date.new(year.to_i, month.to_i, 1).strftime('%m/%d/%Y')]  # for mm/yy drop downs
      end
    elsif [true, false].include?(param)
      values = param
    elsif param.kind_of?(Hash)
      # from Hash with multiple answers per question
      values = param.values.map {|v| CGI.unescape(v)}.select {|v| v.to_s.strip.present?}
    elsif param.kind_of?(String)
      values = param.strip.present? ? [CGI.unescape(param)] : []
    elsif param.kind_of?(Array)
      values = param
    end

    # Hash may contain empty string to force post for no checkboxes
#    values = values.reject {|r| r == ''}
  end

end
