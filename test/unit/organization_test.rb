require 'test_helper'

class OrganizationTest < ActiveSupport::TestCase
  
  should have_many(:roles)
  should have_many(:group_labels)
  should have_many(:activities)
  should have_many(:target_areas)
  should have_many(:organization_memberships)
  should have_many(:people)
  should have_many(:contact_assignments)
  should have_many(:keywords)
  should have_many(:surveys)
  should have_many(:survey_elements)
  should have_many(:questions)
  should have_many(:all_questions)
  should have_many(:followup_comments)
  should have_many(:organizational_roles)
  should have_many(:leaders)
  should have_many(:only_leaders)
  should have_many(:admins)
  should have_many(:all_contacts)
  should have_many(:contacts)
  should have_many(:dnc_contacts)
  should have_many(:completed_contacts)
  should have_many(:no_activity_contacts)
  should have_many(:rejoicables)
  should have_many(:groups)

  # begin methods testing

  context "parent_organization method" do
    setup do
      @org1 = Factory(:organization, id: '1')
      @org2 = Factory(:organization, id: '2', ancestry: '1')
      @org3 = Factory(:organization, id: '3', ancestry: '1/2')
    end
    should "return the ancestor of the org" do
      assert_equal(@org2, @org3.parent_organization, "org2 should be the parent of org3")
    end
    should "return nil if org do not have ancestor" do
      assert_nil(@org1.parent_organization, "org1 should not have parent org")
    end
  end

  context "parent_organization_admins method" do
    setup do
      @person1 = Factory(:person, :email => "person1@email.com")
      @person2 = Factory(:person, :email => "person2@email.com")
      @person3 = Factory(:person, :email => "person3@email.com")
      @person4 = Factory(:person, :email => "person4@email.com")
      @org1 = Factory(:organization, id: '1')
      @org2 = Factory(:organization, id: '2', ancestry: '1')
      @org3 = Factory(:organization, id: '3', ancestry: '1/2')
    end
    should "return the admins of org2" do
      Factory(:organizational_role, organization: @org2, person: @person1, role: Role.admin)
      Factory(:organizational_role, organization: @org2, person: @person2, role: Role.admin)
      results = @org3.parent_organization_admins
      assert_equal(2, results.count, "when org3 dont have admin")
      assert(results.include?(@person1), "person1 should be returned")
      assert(results.include?(@person2), "person2 should be returned")
    end
    should "return the admins of org1 if @org2 dont have admins" do
      Factory(:organizational_role, organization: @org1, person: @person1, role: Role.admin)
      results = @org3.parent_organization_admins
      assert_equal(1, results.count, "when org3 and org2 dont have admin")
      assert(results.include?(@person1), "person1 should be returned")
    end
  end

  context "all_possible_admins method" do
    setup do
      @person1 = Factory(:person, :email => "person1@email.com")
      @person2 = Factory(:person, :email => "person2@email.com")
      @person3 = Factory(:person, :email => "person3@email.com")
      @person4 = Factory(:person, :email => "person4@email.com")
      @org1 = Factory(:organization, id: '1')
      @org2 = Factory(:organization, id: '2', ancestry: '1')
      @org3 = Factory(:organization, id: '3', ancestry: '1/2')
    end
    should "return the admins of org3" do
      Factory(:organizational_role, organization: @org3, person: @person1, role: Role.admin)
      Factory(:organizational_role, organization: @org3, person: @person2, role: Role.admin)
      results = @org3.all_possible_admins
      assert_equal(2, results.count, "when org3 have admins")
      assert(results.include?(@person1), "person1 should be returned")
      assert(results.include?(@person2), "person2 should be returned")
    end
    should "return the admins of org2" do
      Factory(:organizational_role, organization: @org2, person: @person1, role: Role.admin)
      Factory(:organizational_role, organization: @org2, person: @person2, role: Role.admin)
      Factory(:organizational_role, organization: @org2, person: @person3, role: Role.admin)
      results = @org3.all_possible_admins
      assert_equal(3, results.count, "when org3 dont have admin")
      assert(results.include?(@person1), "person1 should be returned")
      assert(results.include?(@person2), "person2 should be returned")
      assert(results.include?(@person3), "person3 should be returned")
    end
    should "return the admins of org1" do
      Factory(:organizational_role, organization: @org1, person: @person1, role: Role.admin)
      Factory(:organizational_role, organization: @org1, person: @person2, role: Role.admin)
      results = @org3.all_possible_admins
      assert_equal(2, results.count, "when org3 and org2 dont have admin")
      assert(results.include?(@person1), "person1 should be returned")
      assert(results.include?(@person2), "person2 should be returned")
    end
    should "return null" do
      results = @org3.all_possible_admins
      assert_nil(results, "when org3 and org2 and org1 dont have admins")
    end
  end

  context "all_possible_admins_with_email method" do
    setup do
      @person1 = Factory(:person, :email => "person1@email.com")
      @person2 = Factory(:person, :email => "person2@email.com")
      @person3 = Factory(:person)
      @person4 = Factory(:person)
      @org1 = Factory(:organization, id: '1')
      @org2 = Factory(:organization, id: '2', ancestry: '1')
      @org3 = Factory(:organization, id: '3', ancestry: '1/2')
    end
    should "return the admins with email of org3" do
      Factory(:organizational_role, organization: @org3, person: @person1, role: Role.admin)
      Factory(:organizational_role, organization: @org3, person: @person3, role: Role.admin)
      results = @org3.all_possible_admins_with_email
      assert_equal(1, results.count, "when org3 have admins")
      assert(results.include?(@person1), "person1 should be returned")
    end
    should "return the admins of org2" do
      Factory(:organizational_role, organization: @org2, person: @person1, role: Role.admin)
      Factory(:organizational_role, organization: @org2, person: @person2, role: Role.admin)
      Factory(:organizational_role, organization: @org2, person: @person3, role: Role.admin)
      results = @org3.all_possible_admins_with_email
      assert_equal(2, results.count, "when org3 dont have admin")
      assert(results.include?(@person1), "person1 should be returned")
      assert(results.include?(@person2), "person2 should be returned")
    end
    should "return the admins of org1" do
      Factory(:organizational_role, organization: @org1, person: @person1, role: Role.admin)
      Factory(:organizational_role, organization: @org1, person: @person2, role: Role.admin)
      Factory(:organizational_role, organization: @org1, person: @person3, role: Role.admin)
      Factory(:organizational_role, organization: @org1, person: @person4, role: Role.admin)
      results = @org3.all_possible_admins_with_email
      assert_equal(2, results.count, "when org3 and org2 dont have admin")
      assert(results.include?(@person1), "person1 should be returned")
      assert(results.include?(@person2), "person2 should be returned")
    end
    should "return null" do
      results = @org3.all_possible_admins_with_email
      assert_nil(results, "when org3 and org2 and org1 dont have admins")
    end
    should "return null if no admin has email" do
      Factory(:organizational_role, organization: @org3, person: @person3, role: Role.admin)
      Factory(:organizational_role, organization: @org3, person: @person4, role: Role.admin)
      results = @org3.all_possible_admins_with_email
      assert_equal(0, results.count, "when org3 and org2 and org1 dont have admins")
    end
  end

  test "test to_s()" do # Every model, in this application, should return .name of the record
    org1 = Factory(:organization, :name => "Chupakabra")
    assert_equal org1.to_s, "Chupakabra", "Organization did not return correct value on to_s method" 
  end

  test "self and children" do

  end

	test "only_leaders should only return people with leader roles not people with admin roles but does not have leader roles" do
    @org = Factory(:organization)
    person1 = Factory(:person, :email => "person1@email.com")
    person2 = Factory(:person, :email => "person2@email.com")
    person3 = Factory(:person, :email => "person3@email.com")
		Factory(:organizational_role, organization: @org, person: person1, role: Role.admin)
		Factory(:organizational_role, organization: @org, person: person2, role: Role.leader)
		Factory(:organizational_role, organization: @org, person: person3, role: Role.admin)
		Factory(:organizational_role, organization: @org, person: person3, role: Role.leader)
		@org.only_leaders.inspect
	end

  test "self and children ids" do
    org1 = Factory(:organization)
    org2 = Factory(:organization, :parent => org1)

    assert_equal org1.self_and_children_ids.sort{ |a, b| 1*(b <=> a) }, [org1.id, org2.id].sort{ |a, b| 1*(b <=> a) }, "Parent organization did not return correct self and children ids"
    #[2, 3, 1].sort{ |a, b| 1*(b <=> a) } == [2, 1, 3].sort{ |a, b| 1*(b <=> a) }    
  end

  test "self and children surveys" do
    org1 = Factory(:organization)
    org2 = Factory(:organization, :parent => org1)
    survey1 = Factory(:survey, :organization => org1)
    survey2 = Factory(:survey, :organization => org2)

    assert_equal org1.self_and_children_surveys.sort{ |a, b| 1*(b <=> a) }, [survey1, survey2].sort{ |a, b| 1*(b <=> a) }, "Parent organization did not return correct self and children surveys"
  end

  test "self and children keywords" do
    org1 = Factory(:organization)
    org2 = Factory(:organization, :parent => org1)
    keyword1 = Factory(:sms_keyword, :organization => org1)
    keyword2 = Factory(:sms_keyword, :organization => org2)

    assert_equal org1.self_and_children_keywords.sort{ |a, b| 1*(b <=> a) }, [keyword1, keyword2].sort{ |a, b| 1*(b <=> a) }, "Parent organization did not return correct self and children keywords"
  end

  test "self and children questions" do #this test is not done
    org1 = Factory(:organization)
    org2 = Factory(:organization, :parent => org1)
    survey1 = Factory(:survey, :organization => org1)
    survey2 = Factory(:survey, :organization => org2)

    #puts org1.self_and_children_questions

    #assert_equal org1.self_and_children_keywords.sort{ |a, b| 1*(b <=> a) }, [keyword1, keyword2].sort{ |a, b| 1*(b <=> a) }, "Parent organization did not return correct self and children keywords"
  end

  test "unassigned_people" do

  end
  
  context "retrieving active keywords" do
    setup do
      @person = Factory(:person)
      @org1 = Factory(:organization)
      @org2 = Factory(:organization)
      @keyword1 = Factory(:sms_keyword, :organization => @org1, state: 'active')
      @keyword2 = Factory(:sms_keyword, :organization => @org1, state: 'active')
      @keyword3 = Factory(:sms_keyword, :organization => @org2, state: 'active')
      @keyword4 = Factory(:sms_keyword, :organization => @org1)
      @keyword5 = Factory(:sms_keyword, :organization => @org2)
    end
    should "return the organization keywords" do
      results = @org1.active_keywords
      assert_equal(results.count, 2, "The resuts should be = 2")
      assert(results.include?(@keyword1), "This should be returned")
      assert(results.include?(@keyword2), "This should be returned")
    end
    should "not return not active keyword" do
      results = @org1.active_keywords
      assert(!results.include?(@keyword4), "This not should be returned")
    end
    should "not return active keyword of other org" do
      results = @org1.active_keywords
      assert(!results.include?(@keyword3), "This not should be returned")
    end
  end

  test "terminology enum" do
    org1 = Factory(:organization)
    org2 = Factory(:organization, :parent => org1)

    assert_equal org1.terminology_enum.sort{ |a, b| 1*(b <=> a) }, [org1.terminology, org2.terminology].uniq.sort{ |a, b| 1*(b <=> a) }, "Organization class did not return correct unique terminologies"
  end

  test "roles" do
    org1 = Factory(:organization)
    role1 = Factory(:role, :organization => org1)
    a = Role.where("organization_id = 0")
    a << role1
    
    assert_equal org1.roles.sort{ |a, b| 1*(b <=> a) }, a.sort{ |a, b| 1*(b <=> a) }, "Organization class did not return correct roles"
  end

  test "<=>(other)" do
    org1 = Factory(:organization, :name => "Zulu")
    org2 = Factory(:organization, :name => "Yack")

    assert_equal(org1<=>(org2), 1, "Organization class returned wrong results for <=> operator")
  end

  test "validation method enum" do

  end

  test "name with keyword count" do
    org1 = Factory(:organization)
    keyword1 = Factory(:sms_keyword, :organization => org1)
    #keyword2 = Factory(:sms_keyword, :organization => org2)

    assert_equal org1.name_with_keyword_count, org1.name + " (#{SmsKeyword.count})", "Organization method name_with_keyword_count does not return right value"
  end

  test "add_member(person_id)" do
    org1 = Factory(:organization)
    person1 = Factory(:person)
    org1.add_member(person1.id)
    om = OrganizationMembership.last
    assert_equal om.organization.to_s + om.person.to_s, org1.to_s + person1.to_s, "Organization method add_member does not correctly add member"
  end

  test "add_leader(person)" do
    user1 = Factory(:user_with_auxs)  #user with a person object
    user2 = Factory(:user_with_auxs)

    org1 = Factory(:organization)

    org1.add_leader(user2.person, user1.person)
    om = OrganizationalRole.last
    assert_equal om.organization.to_s + om.person.to_s + om.role_id.to_s, org1.to_s + user2.person.to_s + Role::LEADER_ID.to_s, "Organization method add_member does not correctly add leader"
  end

  test "add_contact(person)" do
    org1 = Factory(:organization)
    person1 = Factory(:person)
    org1.add_contact(person1)
    om = OrganizationalRole.last
    assert_equal om.organization.to_s + om.person.to_s + om.role_id.to_s, org1.to_s + person1.to_s + Role::CONTACT_ID.to_s, "Organization method add_member does not correctly add contact"
  end

  test "add_admin(person)" do
    org1 = Factory(:organization)
    person1 = Factory(:person)
    org1.add_admin(person1)
    om = OrganizationalRole.last
    assert_equal om.organization.to_s + om.person.to_s + om.role_id.to_s, org1.to_s + person1.to_s + Role::ADMIN_ID.to_s, "Organization method add_member does not correctly add admin"
  end

  test "add_involved(person)" do
    org1 = Factory(:organization)
    person1 = Factory(:person)
    org1.add_involved(person1)
    om = OrganizationalRole.last
    assert_equal om.organization.to_s + om.person.to_s + om.role_id.to_s, org1.to_s + person1.to_s + Role::INVOLVED_ID.to_s, "Organization method add_member does not correctly add involved"
  end

  test "remove_contact(person)" do
    org1 = Factory(:organization)
    person1 = Factory(:person)
    org1.add_contact(person1)
    assert_difference("OrganizationalRole.count", -1, "An organization was not destroyed") do
      org1.remove_contact(person1)
    end
  end

  test "move_contact(person, to_org, keep_contact, current_user)" do # revise!
    person = Factory(:person_with_things)
    contact = Factory(:person)
    org1 = Factory(:organization)
    org2 = Factory(:organization)
    org1.add_contact(contact)
    org1.add_admin(person)
    FollowupComment.create(contact_id: contact.id, commenter_id: person.id, organization_id: org1.id, comment: 'test', status: 'contacted')
    org1.move_contact(contact, org2, "false", person)
    assert_equal(0, org1.contacts.length)
    assert_equal(1, org2.contacts.length)
    assert_equal(0, FollowupComment.where(contact_id: contact.id, organization_id: org1.id).count)
    assert_equal(1, FollowupComment.where(contact_id: contact.id, organization_id: org2.id).count)
  end

  test "create_admin_user" do
    org1 = Factory(:organization)
    person1 = Factory(:person)

    assert_difference "OrganizationalRole.count", 0, "Organization method create_admin_uer created admin user despite absence of Organization person_id" do
      org1.create_admin_user
    end

    org1.person_id = person1.id
    org1.create_admin_user
    om = OrganizationalRole.last
    assert_equal om.organization.to_s + om.person.to_s + om.role_id.to_s, org1.to_s + person1.to_s + Role::ADMIN_ID.to_s, "Organization method create_admin_user does not correctly add admin"
  end

  test "notify_admin_of_request" do

  end

  test "notify_new_leader(person, added_by)" do
  
  end

  # end method testing

  # begin deeper tests

  test "state machines test" do
    # write in this block state machine tests
  end

  context "an organization" do

    should "delete suborganizations when deleted (root organizations cannot be deleted)" do
      # it seems like there comes a problem when you are destroying an organization in which its predecessor tree is more than 2 levels deep
    
      org1 = Factory(:organization)
      org2 = Factory(:organization, :parent => org1)
      org3 = Factory(:organization, :parent => org2)
      org4 = Factory(:organization, :parent => org3)
      org5 = Factory(:organization, :parent => org4)

      assert_difference("Organization.count", -3, "Organizations were not deleted after parent was destroyed.") do 
        org4.destroy
      end
    end

    should "have both name and terminology" do

      assert_difference("Organization.count", 0, "An organization was created despite the absence of terminology") do
        Organization.create(:name => "name")
      end

      assert_difference("Organization.count", 0, "An organization was created despite the absence of name") do
        Organization.create(:terminology => "termi")
      end
      
    end

    should "have at least one parent after creation" do #this test is not yet done
      org = Factory(:organization)
      #puts org
      #puts Factory.attributes_for :organization
      #assert_not_nil org.parent
    end
  end

  test "add initial admin after creating an org" do
    person = Factory(:person)
    assert_difference "OrganizationalRole.count", 1 do
      Factory(:organization, person_id: person.id)
    end
  end
  
  context "Testing the uniqueness of an orgs children" do
    setup do
      @org = Factory(:organization)
      @child = Factory(:organization, parent: @org, name: 'org', terminology: 'org')
      
      @another_org = Factory(:organization)
    end
    
    should "not save a child org if the name is not unique" do
      another_child = Organization.new(:parent => @org, :name => 'org', :terminology => 'org')
      assert !another_child.save
      assert_not_nil another_child.errors[:name]
      assert_equal "Name is not Unique", another_child.errors[:name].first
    end
    
    should "save a child org if the name is uniqie" do
      another_child = Organization.new(:parent => @org, :name => 'wat', :terminology => 'wat')
      assert another_child.save
    end
  
    should "save a child org with the same name from another parent orgs children" do
      another_child = Organization.new(:parent => @another_org, :name => 'org', :terminology => 'org')
      assert another_child.save
    end
  end

  # end deeper tests


 

  
end
