require 'check_digit'

class AnswerSheet < ActiveRecord::Base
  attr_accessible :completed_at, :person_id, :survey_id

  belongs_to :person
  belongs_to :survey
  has_many :answers, class_name: 'Answer', foreign_key: 'answer_sheet_id'

  # def complete?
  #   !completed_at.nil?
  # end

  def valid_person?
    (person.valid? && (!person.primary_phone_number || person.primary_phone_number.valid?))
  end

  def answers_by_question
    answers.group_by(&:question_id)
  end

  def save_survey(answers = nil, notify_on_predefined_questions = true)
    question_set = QuestionSet.new(survey.questions, self)
    question_set.post(answers, self) if answers
    if question_set.save(notify_on_predefined_questions)
      person.save
      update_attribute(:completed_at, Time.now)

      # Ensure that the user/contact will be added as contact in organization after taking survey
      org = survey.organization
      org.add_contact(person) if org.present?
    end
  end

  def to_note
    i = Interaction.new(interaction_type_id: InteractionType.comment.id, privacy_setting: 'organization',
                        organization_id: survey.organization_id, receiver_id: person_id,
                        created_by_id: person_id, updated_by_id: person_id, comment: answers_as_string,
                        created_at: created_at, updated_at: updated_at, timestamp: created_at)
    i.initiators << person
    i
  end

  private

  def answers_as_string
    survey.questions.map do |question|
      answer = answer_for(question)
      next unless answer.present?
      "#{question.label}:\r\n#{answer}\r\n\r\n"
    end.compact.join + "-- Survey Response #{id_with_check} --"
  end

  def answer_for(question)
    return person.send(question.attribute_name) if question.predefined?
    answers.where(question_id: question.id).collect(&:value).compact.reject(&:empty?).to_sentence
  end

  def id_with_check
    CheckDigit::Verhoeff.checksum(id)
  end

  # def has_answer_for?(question_id)
  #   answers_by_question[question_id].present?
  # end
end
