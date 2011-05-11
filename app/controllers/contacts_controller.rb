class ContactsController < ApplicationController
  before_filter :get_person
  before_filter :get_keyword, :only => [:new, :update]
  before_filter :get_answer_sheet, :only => [:new, :update]
  
  def new
    if params[:received_sms_id]
      sms = ReceivedSms.find_by_id(Base62.decode(params[:received_sms_id])) if params[:received_sms_id]
      if sms
        @person.phone_numbers.create!(:number => sms.phone_number, :location => 'mobile') unless @person.phone_numbers.detect {|p| p.number == sms.phone_number}
        sms.update_attribute(:person_id, @person.id) unless sms.person_id
      end
    end
  end
    
  def update
    @person.update_attributes(params[:person]) if params[:person]
    question_set = QuestionSet.new(@keyword.questions, @answer_sheet)
    question_set.post(params[:answers], @answer_sheet)
    question_set.save
    if @person.valid?
      render :thanks
    else
      render :new
    end
  end
  
  def thanks
    
  end
  
  protected
    
    def get_keyword
      @keyword = SmsKeyword.where(:keyword => params[:keyword]).first
    end
    def get_person
      @person = current_user.person
    end
    
    def get_answer_sheet
      @answer_sheet = AnswerSheet.where(:person_id => @person.id, :question_sheet_id => @keyword.question_sheet.id).first || 
                      AnswerSheet.create!(:person_id => @person.id, :question_sheet_id => @keyword.question_sheet.id)
    end
end
