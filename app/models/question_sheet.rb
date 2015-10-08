require 'model_extensions'
# QuestionSheet represents a particular form
class QuestionSheet < ActiveRecord::Base
  belongs_to :questionnable, polymorphic: true
  has_many :pages,
           -> { order('number') }, dependent: :destroy
  has_many :page_elements, through: :pages
  has_many :questions,
           -> { order("#{PageElement.table_name}.position") }, through: :pages
  has_many :archived_questions,
           -> { order("#{PageElement.table_name}.position") }, through: :pages
  has_many :all_questions,
           -> { order("#{PageElement.table_name}.position") }, through: :pages
  has_many :elements,
           -> { order("#{PageElement.table_name}.position") }, through: :pages
  has_many :answer_sheets

  scope :active,
        -> { where(archived: false) }
  scope :archived,
        -> { where(archived: true) }

  validates_presence_of :label
  validates_length_of :label, maximum: 60, allow_nil: true
  validates_uniqueness_of :label

  before_destroy :check_for_answers

  # create a new form with a page already attached
  def self.new_with_page
    question_sheet = new(label: next_label)
    question_sheet.pages.build(label: 'Page 1', number: 1)
    question_sheet
  end

  # def questions
  #   pages.collect(&:questions).flatten
  # end
  #
  # def elements
  #   pages.collect(&:elements).flatten
  # end

  # Pages get duplicated
  # Question elements get associated
  # non-question elements get cloned
  def duplicate
    new_sheet = QuestionSheet.new(attributes)
    new_sheet.label = label + ' - COPY'
    new_sheet.save(validate: false)
    pages.each do |page|
      page.copy_to(new_sheet)
    end
    new_sheet
  end

  private

  # next unused label with "Untitled form" prefix
  def self.next_label
    ModelExtensions.next_label('Untitled form', untitled_labels)
  end

  # returns a list of existing Untitled forms
  # (having a separate method makes it easy to mock in the spec)
  def self.untitled_labels
    QuestionSheet.find(:all, conditions: %(label like 'Untitled form%')).map(&:label)
  end

  def check_for_answers
  end
end
