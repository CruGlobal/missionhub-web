class ApplicationController < ActionController::Base
  before_filter :authenticate_user!, :prepare_for_mobile, :set_locale
  protect_from_forgery  

  protected
  
  def mobile_device?
    if session[:mobile_param]
      session[:mobile_param] == "1"
    else
      request.user_agent =~ /Mobile|webOS/
    end
  end
  helper_method :mobile_device?

  def prepare_for_mobile
    session[:mobile_param] = params[:mobile] if params[:mobile]
    request.format = :mobile if mobile_device?
  end
  
  def current_person
    current_user.person
  end
  helper_method :current_person
  
  def get_guid_from_ticket(ticket)
    begin
      ticket.response.to_s.match(/ssoGuid>([A-Z0-9\-]*)/)[1]
    rescue => e
      raise e.message + ' -- ' + ticket.response.inspect
    end
  end
  

  def set_locale
    I18n.locale = params[:locale] if params[:locale]
  end
  
end
