class LeadersController < ApplicationController
  respond_to :html, :js

  def leader_sign_in
    # Reconcile the person coming from a leader link with the link itself.
    # This is for the case where the person gets entered with one email, but has a different email for FB
    if params[:token].present? && params[:user_id].present?
      @token = params[:token]
      @user = User.find(params[:user_id])
      if @user.remember_token == @token && @user.remember_token_expires_at >= Time.now
        if current_user == @user
          @user.update_attributes(remember_token_expires_at: Time.now)
          redirect_to user_root_path
        else
          if current_user.person.has_email?(@user.username)
            current_user.merge(@user)
            @user.destroy
            if current_user.person.present?
              redirect_to all_contacts_path(assigned_to: current_user.person.id)
            else
              redirect_to '/mycontacts'
            end
          else
            @valid_token = true
            render layout: 'mhub'
          end
        end
      else
        @valid_token = false
        render layout: 'mhub'
      end
    else
      redirect_to root_path
    end
  end

  def merge_leader_accounts
    if params[:token].present? && params[:user_id].present?
      @token = params[:token]
      @user = User.find(params[:user_id])
      if @user.remember_token == @token && @user.remember_token_expires_at >= Time.now
        if current_user == @user
          @user.update_attributes(remember_token_expires_at: Time.now)
          redirect_to user_root_path
        else
          current_user.merge(@user)
          @user.destroy
          if current_user.person.present?
            redirect_to all_contacts_path(assigned_to: current_user.person.id)
          else
            redirect_to '/mycontacts'
          end
        end
      else
        @valid_token = false
        render 'leader_sign_in', layout: 'mhub'
      end
    else
      redirect_to root_path
    end
  end

  def sign_out_and_leader_sign_in
    if params[:token] && params[:user_id]
      sign_out(current_user)
      redirect_to leader_link_path(params[:token], params[:user_id])
    else
      redirect_to user_root_path
    end
  end

  def search
    if params[:name].present?
      scope = Person.search_by_name(params[:name], [current_organization.id])
      @people = scope.includes(:user)
      if params[:show_all].to_s == 'true'
        @total = @people.all.length
      else
        @people = @people.limit(10)
        @total = scope.count
      end
      @people
      render layout: false
    else
      render nothing: true
    end
  end

  def new
    names = params[:name].to_s.split(' ')
    @person = Person.new(first_name: names[0], last_name: names[1..-1].join(' '))
    @email = @person.email_addresses.new
    @phone = @person.phone_numbers.new
  end

  def destroy
    @person = Person.find(params[:id])
    permissions = OrganizationalPermission.where(person_id: @person.id, organization_id: current_organization.id, permission_id: Permission.user_ids, archive_date: nil, deleted_at: nil)
    if permissions
      permissions.each(&:archive)
      # make any contacts assigned to this person go back to unassinged
      @contacts = @person.contact_assignments.where(organization_id: current_organization.id).destroy_all
      current_organization.add_contact(@person)
    end
  end

  def create
    @organization = current_organization
    if @person
      @notify = params[:notify] == '1'
    else
      @person = Person.find(params[:person_id])
      @notify = true
    end
    # Make sure we have a user for this person
    unless @person.user
      @new_person = @person.create_user!
      unless @new_person
        @person.reload
        # we need a valid email address to make a leader
        @email = @person.primary_email_address || @person.email_addresses.new
        @phone = @person.primary_phone_number || @person.phone_numbers.new
        flash[:error] = I18n.t('leaders.create.no_user_account')
        render(:edit) && return
      end
      @person = @new_person
    end
    current_organization.add_leader(@person, current_person)
    render :create
  end

  def update
    @person = Person.find(params[:id])
    if params[:person]
      email_attributes = params[:person].delete(:email_address) || {}
      phone_attributes = params[:person].delete(:phone_number) || {}
      if email_attributes[:email].present?
        @email = @person.email_addresses.where(email: email_attributes[:email]).first_or_create
      end
      if phone_attributes[:phone].present?
        @phone = @person.phone_numbers.where(number: PhoneNumber.strip_us_country_code(phone_attributes[:phone])).first_or_create
      end
      @person.save
      @person.update_attributes(params[:person])
    end
    @required_fields = { 'First Name' => @person.first_name, 'Last Name' => @person.last_name, 'Gender' => @person.gender, 'Email' => @email.try(:email) }
    @person.valid?; @email.try(:valid?); @phone.try(:valid?)
    unless @required_fields.values.all?(&:present?)
      flash.now[:error] = 'Please fill in all fields<br />'
      @required_fields.each do |k, v|
        flash.now[:error] += k + ' is required.<br />' unless v.present?
      end
      flash.now[:error] = "<font color='red'>" + flash.now[:error] + '</font>'
      render(:edit) && return
    end
    create && return
  end

  def add_person
    @person = create_person(params[:person])
    @email = @person.email_addresses.first
    @phone = @person.phone_numbers.first

    @required_fields = { 'First Name' => @person.first_name, 'Last Name' => @person.last_name, 'Gender' => @person.gender, 'Email' => @email.try(:email) }
    @person.valid?; @email.try(:valid?); @phone.try(:valid?)

    error_message = ''
    unless @required_fields.values.all?(&:present?)
      @required_fields.each do |k, v|
        error_message += k + ' is required.<br />' unless v.present?
      end
    end

    error_message += "Email Address isn't valid.<br />" if @email.present? && !@email.valid?

    if error_message.present?
      flash.now[:error] = "<font color='red'>" + error_message + '</font>'
      render(:new) && return
    end

    @person.email ||= @email.email
    @person.save!

    create && return
  end

  def find_by_email_addresses
    @matched_emails = []
    return unless params[:find_leader_by_email]
    emails = params[:find_leader_by_email].collect { |_k, e| e[0] }.reject(&:blank?)
    emails = EmailAddress.where(email: emails).includes(person: [:user, :organizational_permissions])
             .where.not(users: { id: [nil, current_user.id] }, organizational_permissions: { id: nil })
             .where(organizational_permissions: { deleted_at: nil, archive_date: nil })
    emails.each do |email|
      LeaderMailer.delay.resend(email, current_user)
    end
    @matched_emails = emails.collect(&:email)
  end

  def authenticate_user!
    if action_name == 'leader_sign_in' && params[:token].present? && params[:user_id].present?
      user = User.find_by(remember_token: params[:token], id: params[:user_id])
      session[:user_with_token] = user.id if user
    end
    super
  end
end
