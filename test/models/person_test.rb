require 'test_helper'

class PersonTest < ActiveSupport::TestCase
  should belong_to(:user)
  should validate_presence_of(:first_name)
  # should validate_presence_of(:last_name)
  should have_one(:primary_phone_number)
  should have_one(:primary_email_address)
  should have_many(:phone_numbers)
  should have_many(:locations)
  should have_many(:interests)
  should have_many(:education_histories)
  should have_many(:email_addresses)
  should have_many(:organizations)
  should have_many(:answer_sheets)
  should have_many(:contact_assignments)
  should have_many(:assigned_tos)
  should have_many(:assigned_contacts)



  context "user_permission_for_org method" do
    setup do
      @person = FactoryGirl.create(:person)
      @organization = FactoryGirl.create(:organization)
      @organization.add_user(@person)
    end
    should "return the user organizational_permission" do
      assert_equal 1, @person.organizational_permissions_for_org(@organization).count, "check permission count for org"
      result = @person.user_permission_for_org(@organization)
      assert_equal Permission.user.id, result.permission_id, "check returned permission"
    end
  end


  context "has_interaction_in_org? method" do
    setup do
      @person = FactoryGirl.create(:person)
      @other_person = FactoryGirl.create(:person)
      @organization = FactoryGirl.create(:organization)
      @organization.add_contact(@person)
      @organization.add_contact(@other_person)
      @interaction = FactoryGirl.create(:interaction, organization: @organization, receiver: @other_person, creator: @person1, comment: "Comment")
    end
    should "return a true if there's an interaction" do
      results = @other_person.has_interaction_in_org?([@interaction.interaction_type_id], @organization)
      assert results
    end
    should "return a false if there's no interaction" do
      results = @person.has_interaction_in_org?([@interaction.interaction_type_id], @organization)
      assert !results
    end
  end

  context "labeled_in_org method" do
    setup do
      @person = FactoryGirl.create(:person)
      @organization = FactoryGirl.create(:organization)
      @organization.add_contact(@person)
      @label = FactoryGirl.create(:label, organization: @organization)
      @org_label = FactoryGirl.create(:organizational_label, organization: @organization, person: @person, label: @label)
    end
    should "return a boolean if there's a organizational_label" do
      results = @person.labeled_in_org?(@label, @organization)
      assert results
    end
  end

  context "ensure_single_permission_for_org_id method" do
    setup do
      @person1 = FactoryGirl.create(:person)
      @person2 = FactoryGirl.create(:person)
      @person3 = FactoryGirl.create(:person)
      @organization = FactoryGirl.create(:organization)
      @organization.add_contact(@person1)
      @organization.add_contact(@person2)
      FactoryGirl.create(:organizational_permission, person: @person1, organization: @organization, permission: Permission.user)

      @other_organization = FactoryGirl.create(:organization)
      @other_organization.add_contact(@person1)
    end
    should "ensure single permission" do
      assert_equal 2, @person1.organizational_permissions_for_org(@organization).count, "check permission count for org"
      @person1.ensure_single_permission_for_org_id(@organization.id)
      assert_equal 1, @person1.organizational_permissions_for_org(@organization).count, "check if permission is single"
      assert_equal Permission.user.id, @person1.organizational_permissions_for_org(@organization).first.permission_id, "check remaining permission"
    end
    should "not touch other org's permission" do
      assert_equal 1, @person1.organizational_permissions_for_org(@other_organization).count, "check permission count for other org"
      @person1.ensure_single_permission_for_org_id(@organization.id)
      assert_equal 1, @person1.organizational_permissions_for_org(@other_organization).count, "check permission count for other org"
    end
    should "prioritize specified permission" do
      @person1.ensure_single_permission_for_org_id(@organization.id, Permission.no_permissions.id)
      assert_equal 1, @person1.organizational_permissions_for_org(@organization).count, "check if permission is single"
      assert_equal Permission.no_permissions.id, @person1.organizational_permissions_for_org(@organization).first.permission_id, "check remaining permission"
    end
  end

  context "with_label scope" do
    setup do
      @person1 = FactoryGirl.create(:person)
      @person2 = FactoryGirl.create(:person)
      @person3 = FactoryGirl.create(:person)
      @organization = FactoryGirl.create(:organization)
      @organization.add_contact(@person1)
      @organization.add_contact(@person2)
      @label = FactoryGirl.create(:label, organization: @organization)
      FactoryGirl.create(:organizational_label, organization: @organization, person: @person1, label: @label)
    end
    should "return people with labels" do
      results = @organization.all_people.with_label(@label, @organization)
      assert_equal 1, results.count
      assert results.include?(@person1)
    end
    should "not return people without labels" do
      results = @organization.all_people.with_label(@label, @organization)
      assert !results.include?(@person2)
      assert !results.include?(@person3)
    end
  end

  context "ensure_single_permission_for_org_id method" do
    setup do
      @person = FactoryGirl.create(:person)
      @org = FactoryGirl.create(:organization, id: 1)
      @other_org = FactoryGirl.create(:organization, id: 2)
    end
    should "limit a person to a single permission" do
      FactoryGirl.create(:organizational_permission, person: @person, organization: @org, permission: Permission.user)
      FactoryGirl.create(:organizational_permission, person: @person, organization: @org, permission: Permission.no_permissions)
      FactoryGirl.create(:organizational_permission, person: @person, organization: @org, permission: Permission.admin)
      assert_equal 3, @person.organizational_permissions.where(organization_id: @org.id).count
      @person.ensure_single_permission_for_org_id(@org.id)
      assert_equal 1, @person.organizational_permissions.where(organization_id: @org.id).count
    end
    should "prioritize admin permission" do
      FactoryGirl.create(:organizational_permission, person: @person, organization: @org, permission: Permission.user)
      FactoryGirl.create(:organizational_permission, person: @person, organization: @org, permission: Permission.no_permissions)
      FactoryGirl.create(:organizational_permission, person: @person, organization: @org, permission: Permission.admin)
      FactoryGirl.create(:email_address, person_id: @person.id)
      assert_equal 3, @person.organizational_permissions.where(organization_id: @org.id).count
      @person.ensure_single_permission_for_org_id(@org.id)
      assert_equal 1, @person.organizational_permissions.where(organization_id: @org.id).count
      assert_equal Permission.admin, @person.permission_for_org_id(@org.id)
    end
    should "prioritize user permission" do
      FactoryGirl.create(:organizational_permission, person: @person, organization: @org, permission: Permission.user)
      FactoryGirl.create(:organizational_permission, person: @person, organization: @org, permission: Permission.no_permissions)
      FactoryGirl.create(:email_address, person_id: @person.id)
      assert_equal 2, @person.organizational_permissions.where(organization_id: @org.id).count
      @person.ensure_single_permission_for_org_id(@org.id)
      assert_equal 1, @person.organizational_permissions.where(organization_id: @org.id).count
      assert_equal Permission.user, @person.permission_for_org_id(@org.id)
    end
    # Removed to avoid automated downgrade of permission
    # should "disregard the admin permission if no email present?" do
    #   FactoryGirl.create(:organizational_permission, person: @person, organization: @org, permission: Permission.admin)
    #   FactoryGirl.create(:organizational_permission, person: @person, organization: @org, permission: Permission.no_permissions)
    #   assert_equal 2, @person.organizational_permissions.where(organization_id: @org.id).count
    #   @person.ensure_single_permission_for_org_id(@org.id)
    #   assert_equal 1, @person.organizational_permissions.where(organization_id: @org.id).count
    #   assert_equal Permission.no_permissions, @person.permission_for_org_id(@org.id)
    # end
    # should "disregard the user permission if no email present?" do
    #   FactoryGirl.create(:organizational_permission, person: @person, organization: @org, permission: Permission.user)
    #   FactoryGirl.create(:organizational_permission, person: @person, organization: @org, permission: Permission.no_permissions)
    #   assert_equal 2, @person.organizational_permissions.where(organization_id: @org.id).count
    #   @person.ensure_single_permission_for_org_id(@org.id)
    #   assert_equal 1, @person.organizational_permissions.where(organization_id: @org.id).count
    #   assert_equal Permission.no_permissions, @person.permission_for_org_id(@org.id)
    # end
    should "leave the contact permission" do
      FactoryGirl.create(:organizational_permission, person: @person, organization: @org, permission: Permission.no_permissions)
      assert_equal 1, @person.organizational_permissions.where(organization_id: @org.id).count
      @person.ensure_single_permission_for_org_id(@org.id)
      assert_equal 1, @person.organizational_permissions.where(organization_id: @org.id).count
      assert_equal Permission.no_permissions, @person.permission_for_org_id(@org.id)
    end
  end

  context "create a person from params" do
    should "not fail if there's no phone number when adding a person who already exists" do
      FactoryGirl.create(:user_with_auxs, username: 'test@uscm.org')
      person = Person.new_from_params({"email_address" => {"email" => "test@uscm.org"},"first_name" => "Test","last_name" => "Test","phone_number" => {"number" => ""}})
      assert_nil(person.phone_numbers.first)
    end
  end

  context "get people functions" do
    should "return people that are updated within the specified date_rage" do
      @person = FactoryGirl.create(:person, date_attributes_updated: "2012-07-25".to_date)

      results = Person.find_by_person_updated_by_daterange("2012-07-01".to_date, "2012-07-31".to_date)
      assert(results.include?(@person), "results should include the updated person within the range")

      results = Person.find_by_person_updated_by_daterange("2012-07-20".to_date, "2012-07-01".to_date)
      assert(!results.include?(@person), "results should not include the updated person after the given range")

      results = Person.find_by_person_updated_by_daterange("2012-07-28".to_date, "2012-07-31".to_date)
      assert(!results.include?(@person), "results should not include the updated person before the given range")
    end
    should "return people based on highest default permissions" do
      @org = FactoryGirl.create(:organization)

      @person1 = FactoryGirl.create(:person, first_name: 'Leader')
      @person2 = FactoryGirl.create(:person, first_name: 'Contact')
      @person3 = FactoryGirl.create(:person, first_name: 'Admin')
      @org_permission1 = FactoryGirl.create(:organizational_permission, person: @person1, organization: @org1, permission: Permission.user)
      @org_permission2 = FactoryGirl.create(:organizational_permission, person: @person2, organization: @org1, permission: Permission.no_permissions)
      @org_permission3 = FactoryGirl.create(:organizational_permission, person: @person3, organization: @org1, permission: Permission.admin)

      results = Person.order_by_highest_default_permission('permission')
      assert_equal(results[0].first_name, 'Contact', "first person of the results should be the contact")
      assert_equal(results[1].first_name, 'Leader', "second person of the results should be the leader")
      assert_equal(results[2].first_name, 'Admin', "third person of the results should be the admin")

      results = Person.order_by_highest_default_permission('permission asc')
      assert_equal(results[0].first_name, 'Admin', "first person of the results should be the admin when order is ASC")
      assert_equal(results[1].first_name, 'Leader', "second person of the results should be the leader when order is ASC")
      assert_equal(results[2].first_name, 'Contact', "third person of the results should be the contact when order is ASC")
    end
    context "person's survey functions" do
      setup do
        @org = FactoryGirl.create(:organization)

        @survey1 = FactoryGirl.create(:survey, organization: @org)
        @survey2 = FactoryGirl.create(:survey, organization: @org)
        @survey3 = FactoryGirl.create(:survey, organization: @org)
        @survey4 = FactoryGirl.create(:survey, organization: @org)

        @person1 = FactoryGirl.create(:person, first_name: 'First Person')
        @person2 = FactoryGirl.create(:person, first_name: 'Second Person')

        @answer_sheet1 = FactoryGirl.create(:answer_sheet, person: @person1, survey: @survey1, updated_at: "2012-07-02".to_date)
        @answer_sheet2 = FactoryGirl.create(:answer_sheet, person: @person1, survey: @survey2, updated_at: "2012-07-01".to_date)
        @answer_sheet3 = FactoryGirl.create(:answer_sheet, person: @person1, survey: @survey3, updated_at: "2012-07-03".to_date)
        @answer_sheet4 = FactoryGirl.create(:answer_sheet, person: @person2, survey: @survey4, updated_at: "2012-07-03".to_date)
      end

      should "return all answer_sheets of a person in completed_answer_sheets function" do
        results = @person1.completed_answer_sheets(@org)
        assert_equal(results[0], @answer_sheet3, "first result should be the 3rd answer sheet")
        assert_equal(results[1], @answer_sheet1, "second result should be the 1st answer sheet")
        assert_equal(results[2], @answer_sheet2, "third result should be the 2nd answer sheet")
      end

      should "not return an answer_sheets which is not answered by the person in completed_answer_sheets function" do
        results = @person1.completed_answer_sheets(@org)
        assert !results.include?(@answer_sheet4)
      end

      should "return the latest answer_sheet of a person in latest_answer_sheet function" do
        results = @person1.latest_answer_sheet(@org)
        assert_equal(results, @answer_sheet3, "should be the 3rd answer sheet")
      end

      should "not return the latest answer_sheet of other person in latest_answer_sheet function" do
        result = @person1.latest_answer_sheet(@org)
        assert_not_equal result, @answer_sheet4
      end
    end

    should "return people based on last answered survey" do
      @org = FactoryGirl.create(:organization)
      @survey = FactoryGirl.create(:survey)

      @person1 = FactoryGirl.create(:person, first_name: 'First Answer')
      @person2 = FactoryGirl.create(:person, first_name: 'Second Answer')
      @person3 = FactoryGirl.create(:person, first_name: 'Last Answer')
      FactoryGirl.create(:organizational_permission, person: @person1, organization: @org, permission: Permission.no_permissions)
      FactoryGirl.create(:organizational_permission, person: @person2, organization: @org, permission: Permission.no_permissions)
      FactoryGirl.create(:organizational_permission, person: @person3, organization: @org, permission: Permission.no_permissions)
      @as1 = FactoryGirl.create(:answer_sheet, person: @person1, survey: @survey, updated_at: "2013-07-01".to_date)
      @as2 = FactoryGirl.create(:answer_sheet, person: @person2, survey: @survey, updated_at: "2013-07-02".to_date)
      @as3 = FactoryGirl.create(:answer_sheet, person: @person3, survey: @survey, updated_at: "2013-07-03".to_date)
      results = Person.get_and_order_by_latest_answer_sheet_answered('ASC', @org.id)
      # assert_equal(@person1.first_name, results[0].first_name, "first result should be the first person who answered")
      # assert_equal(@person2.first_name, results[1].first_name, "second result should be the second person who answered")
      # assert_equal(@person3.first_name, results[2].first_name, "third result should be the last person who answered")
    end

    should "return people assigned to an org" do
      @org1 = FactoryGirl.create(:organization, name: 'Org 1')
      @org2 = FactoryGirl.create(:organization, name: 'Org 2')
      @leader = FactoryGirl.create(:person, first_name: 'Leader')
      @person = FactoryGirl.create(:person)

      @assignment1 = FactoryGirl.create(:contact_assignment, organization: @org1, person: @person, assigned_to: @leader)
      @assignment2 = FactoryGirl.create(:contact_assignment, organization: @org2, person: @person, assigned_to: @leader)

      results = @person.assigned_tos_by_org(@org1)
      assert(results.include?(@assignment1), "results should include contact_assignment for org 1")

      results = @person.assigned_tos_by_org(@org2)
      assert(results.include?(@assignment2), "results should include contact_assignment for org 2")
    end
  end

  context "person organizations and sub-organizations" do

    setup do
      @person = FactoryGirl.create(:person)
      @another_person = FactoryGirl.create(:person)
    end

    should "not show children if show_sub_orgs is false" do
      @org1 = FactoryGirl.create(:organization, person_id: @person.id, id: 1)
      @org2 = FactoryGirl.create(:organization, show_sub_orgs: false, person_id: @person.id, id: 2, ancestry: "1")
      @org3 = FactoryGirl.create(:organization, person_id: @person.id, id: 3, ancestry: "1/2")
      @org4 = FactoryGirl.create(:organization, person_id: @another_person.id, id: 4, ancestry: "1/2/3")
      orgs = @person.orgs_with_children
      assert(orgs.include?(@org1), "root should be included, if Person is leader.")
      assert(orgs.include?(@org2), "this should be included because parent shows sub orgs")
      assert(orgs.include?(@org3), "this should not be included because parent doesnt show sub orgs")
      assert(!orgs.include?(@org4), "this should not be included")
      assert_equal(orgs.count, 3, "duplicate entries are present.")

      other_orgs = @another_person.orgs_with_children
      assert(!other_orgs.include?(@org1), "this should not be included")
      assert(!other_orgs.include?(@org2), "this should not be included")
      assert(!other_orgs.include?(@org3), "this should not be included")
      assert(other_orgs.include?(@org4), "this should be included because other person has permission")
    end

    should "show multiple-generations of children as long as show_sub_orgs is true" do
      @org1 = FactoryGirl.create(:organization, person_id: @person.id, id: 1)
      @org2 = FactoryGirl.create(:organization, person_id: @another_person.id, id: 2, ancestry: "1")
      @org3 = FactoryGirl.create(:organization, person_id: @another_person.id, id: 3, ancestry: "1/2")
      @org4 = FactoryGirl.create(:organization, person_id: @another_person.id, id: 4, ancestry: "1/2/3")
      orgs = @person.orgs_with_children
      assert(orgs.include?(@org1), "root should be included, if Person is leader.")
      assert(orgs.include?(@org2), "this should be included because parent shows sub orgs")
      assert(!orgs.include?(@org3), "this should not be included since another person owns this org")
      assert(!orgs.include?(@org4), "this should not be included since another person owns this org")

      other_orgs = @another_person.orgs_with_children
      assert(!other_orgs.include?(@org1), "this should not be included")
      assert(other_orgs.include?(@org2), "this should not be included")
      assert(other_orgs.include?(@org3), "this should be included")
      assert(other_orgs.include?(@org4), "this should be included")
    end

    should "show multiple generations" do
      @org1 = FactoryGirl.create(:organization, person_id: @another_person.id, id: 1)
      @org2 = FactoryGirl.create(:organization, person_id: @person.id, id: 2, ancestry: "1")
      @org3 = FactoryGirl.create(:organization, person_id: @another_person.id, id: 3, ancestry: "1/2")
      @org4 = FactoryGirl.create(:organization, person_id: @another_person.id, id: 4, ancestry: "1/2/3")
      orgs = @person.orgs_with_children
      assert(!orgs.include?(@org1), "not included since Person is not leader")
      assert(orgs.include?(@org2), "this should be included because parent shows sub orgs")
      assert(orgs.include?(@org3), "this should be included because parent shows sub orgs")
      assert(!orgs.include?(@org4), "this should not be included since another person owns this org")

      other_orgs = @another_person.orgs_with_children
      assert(other_orgs.include?(@org1), "this should be included")
      assert(other_orgs.include?(@org2), "this should be included since parent shows sub orgs")
      assert(other_orgs.include?(@org3), "this should be included")
      assert(other_orgs.include?(@org4), "this should be included")
    end

  end

  context "all_organization_and_children function" do
    should "return child orgs" do
      @person = FactoryGirl.create(:person)
      @org = FactoryGirl.create(:organization, id: 1)
      @org1 = FactoryGirl.create(:organization, id: 2, ancestry: "1")
      @org2 = FactoryGirl.create(:organization, id: 3, ancestry: "1")
      @org3 = FactoryGirl.create(:organization, id: 4, ancestry: "1/2")
      @org.add_admin(@person)

      results = @person.all_organization_and_children
      assert(results.include?(@org1), "Organization1 should be included")
      assert(results.include?(@org2), "Organization2 should be included")
      assert(results.include?(@org3), "Organization3 should be included")
    end
  end

  context "getting the phone number" do
    setup do
      @person = FactoryGirl.create(:person)
    end
    should "should return the phone_number if it exists" do
      mobile_number = @person.phone_numbers.create(number: '1111111111', location: 'mobile')
      assert_equal(@person.phone_number, '1111111111', 'this should return the mobile number')
    end
  end

  context "getting archived people" do
    setup do
      @org1 = FactoryGirl.create(:organization)
      @org2 = FactoryGirl.create(:organization)

      @person1 = FactoryGirl.create(:person)
      @person2 = FactoryGirl.create(:person)
      @person3 = FactoryGirl.create(:person)
      @person4 = FactoryGirl.create(:person)
      @org_permission1 = FactoryGirl.create(:organizational_permission, person: @person1,
                           organization: @org1, permission: Permission.no_permissions, archive_date: Date.today)
      @org_permission2 = FactoryGirl.create(:organizational_permission, person: @person2,
                           organization: @org1, permission: Permission.no_permissions)
      @org_permission4 = FactoryGirl.create(:organizational_permission, person: @person4,
                           organization: @org2, permission: Permission.no_permissions)
    end
    should "return all included person that has active permission" do
      results = @org1.people.archived_included
      assert_equal(results.count, 2)
    end
    should "not return a deleted person" do
      results = @org1.people.archived_included
      assert(!results.include?(@person3), "Person 3 should not be included")
    end
    should "not return person from other org" do
      results = @org1.people.archived_included
      assert(!results.include?(@person4), "Person 3 should not be included")
    end
    should "return all not included person that has active permission" do
      results = @org1.people.archived_not_included
      assert_equal(results.count, 1)
    end
    should "not return a person with archive_date" do
      results = @org1.people.archived_not_included
      assert(!results.include?(@person1), "Person 1 should not be included")
    end
  end

  context "removing contact assignment" do
    setup do
      @leader1 = FactoryGirl.create(:person)
      @leader2 = FactoryGirl.create(:person)
      @leader3 = FactoryGirl.create(:person)
      @org1 = FactoryGirl.create(:organization)
      @org2 = FactoryGirl.create(:organization)
      @person1 = FactoryGirl.create(:person)
      @person2 = FactoryGirl.create(:person)
      @person3 = FactoryGirl.create(:person)

      @assignment1 = FactoryGirl.create(:contact_assignment, organization: @org1, person: @person1, assigned_to: @leader1)
      @assignment2 = FactoryGirl.create(:contact_assignment, organization: @org1, person: @person2, assigned_to: @leader1)
      @assignment3 = FactoryGirl.create(:contact_assignment, organization: @org1, person: @person3, assigned_to: @leader2)
      @assignment4 = FactoryGirl.create(:contact_assignment, organization: @org2, person: @person1, assigned_to: @leader1)
    end
    should "delete assigned contacts" do
      @leader1.remove_assigned_contacts(@org1)
      assert(!ContactAssignment.all.include?(@assignment1), "This assignment should be deleted")
      assert(!ContactAssignment.all.include?(@assignment2), "This assignment should be deleted")
    end
    should "not delete assigned contacts to other leader" do
      @leader1.remove_assigned_contacts(@org1)
      assert(ContactAssignment.all.include?(@assignment3), "This assignment should not be deleted")
    end
    should "not delete assigned contacts from other org" do
      @leader1.remove_assigned_contacts(@org1)
      assert(ContactAssignment.all.include?(@assignment4), "This assignment should not be deleted")
    end
    should "not delete any assignments if no one is assigned to a leader" do
      @leader3.remove_assigned_contacts(@org1)
      initial_assignment_count = ContactAssignment.count
      assert_equal(initial_assignment_count, ContactAssignment.count)
    end
  end

  context "merging a contact" do
    setup do
      @contact = FactoryGirl.create(:person)
      @org = FactoryGirl.create(:organization)

      @person = FactoryGirl.create(:person)
      @person_phone1 = @person.phone_numbers.create(number: '1111111', location: 'mobile')
      @person_location1 = @person.locations.create(provider: "provider", name: "Location1", location_id: "1")
      @person_friend1 = Friend.new("1", 'Friend1', @person, 'provider')
      @person_interest1 = @person.interests.create(provider: "provider", name: "Interest1",
                                                   interest_id: "1", category: "category")
      @person_education1 = @person.education_histories.create(school_type: "HighSchool", provider: "provider",
                                                              school_name: "SchoolName1", school_id: "1")
      @person_followup1 = @person.followup_comments.create(contact_id: @contact.id, comment: "Comment1",
                                                           organization_id: @org.id)
      @person_comment1 = @person.comments_on_me.create(commenter_id: @contact.id, comment: "Comment1",
                                                       organization_id: @org.id)
      @person_email1 = @person.email_addresses.create(email: 'person@email.com')

      @other = FactoryGirl.create(:person)
      @other_phone1 = @other.phone_numbers.create(number: '3333333', location: 'mobile')
      @other_location1 = @other.locations.create(provider: "provider", name: "Location2", location_id: "2")
      @other_friend1 = Friend.new("2", 'Friend2', @other, 'provider')
      @other_interest1 = @other.interests.create(provider: "provider", name: "Interest2",
                                                 interest_id: "2", category: "category")
      @other_education1 = @other.education_histories.create(school_type: "HighSchool", provider: "provider",
                                                            school_name: "SchoolName2", school_id: "2")
      @other_followup1 = @other.followup_comments.create(contact_id: @contact.id, comment: "Comment2",
                                                         organization_id: @org.id)
      @other_comment1 = @other.comments_on_me.create(commenter_id: @contact.id, comment: "Comment2",
                                                     organization_id: @org.id)
      @other_email1 = @other.email_addresses.create(email: 'other@email.com')
    end
    should "merge the phone numbers" do
      @person.merge(@other)
      assert(@person.phone_numbers.include?(@person_phone1), "Person should still have its phone number")
      assert(@person.phone_numbers.include?(@other_phone1), "Person should aquire other person's phone number data")
    end
    should "merge the locations" do
      @person.merge(@other)
      assert(@person.locations.include?(@person_location1), "Person should still have its location")
      assert(@person.locations.include?(@other_location1), "Person should aquire other person's location data")
    end
    should "merge the friends" do
      @person.merge(@other)
      assert(Friend.followers(@person).include?(@person_friend1.uid), "Person should still have its friend")
      assert(Friend.followers(@person).include?(@other_friend1.uid), "Person should aquire other person's friend data")
    end
    should "merge the interests" do
      @person.merge(@other)
      assert(@person.interests.include?(@person_interest1), "Person still have its interest")
      assert(@person.interests.include?(@other_interest1), "Person should aquire other person's interest data")
    end
    should "merge the educational history" do
      @person.merge(@other)
      assert(@person.education_histories.include?(@person_education1), "Person still have its education history")
      assert(@person.education_histories.include?(@other_education1), "Person should aquire other person's education history data")
    end
    should "merge the followup comments" do
      @person.merge(@other)
      assert_equal(@person_followup1.commenter_id, @person.id, "Person still have its followup comment")
      assert_equal(@other_followup1.commenter_id, @person.id, "Person should aquire other person's followup comment data")
    end
    should "merge the comments from other people" do
      @person.merge(@other)
      assert_equal(@person_comment1.contact_id, @person.id, "Person still have its comments from other people")
      assert_equal(@other_comment1.contact_id, @person.id, "Person should aquire other person's comments from other people data")
    end
    should "merge the email address" do
      @person.merge(@other)
      assert(@person.email_addresses.include?(@person_email1), "Person still have its email address")
      assert(@person.email_addresses.include?(@other_email1), "Person should aquire other person's email address data")
    end
  end

  context "a person" do
    setup do
      @person = FactoryGirl.create(:person_without_email)
      @authentication = FactoryGirl.create(:authentication)
    end
    should "output the person's correct full name" do
      assert_equal(@person.to_s, "John Doe")
    end

    context "has a gender which" do
      should "be set correctly for male case" do
        @person.gender = "Male"
        assert_equal(@person.gender, "Male")
        @person.gender = '1'
        assert_equal(@person.gender,"Male")
      end
      should "be set correctly for female case" do
        @person.gender = "Female"
        assert_equal(@person.gender,"Female")
        @person.gender = '0'
        assert_equal(@person.gender,"Female")
      end
    end

    context "get friendships" do
      should "get friends" do
        #make sure # of friends from MiniFB = # written into DB
        existing_friends = @person.friend_uids
        @x = @person.get_friends(@authentication, TestFBResponses::FRIENDS)
        assert_equal(@x, @person.friend_uids.length + existing_friends.length )
      end

      should "update friends" do
        friend1 = Friend.new('1', 'Test User', @person)
        x = @person.update_friends(@authentication, TestFBResponses::FRIENDS)

        # Make sure new friends get deleted
        assert(!@person.friend_uids.include?(friend1.uid))

      end

    end

    should "not create a duplicate email when adding an email they already have" do
      primary_email = @person.email_addresses.create(email: 'test1@example.com')
      assert primary_email.primary?
      secondary_email = @person.email_addresses.create(email: 'test2@example.com')
      assert_no_difference "EmailAddress.count" do
        @person.email = 'test2@example.com'
        @person.save
      end
    end

    should "get & update interests" do
      x = @person.get_interests(@authentication, TestFBResponses::INTERESTS)
      assert(x > 0, "Make sure we now have at least one interest")
      assert(@person.interests.first.name.is_a? String)
    end

    should "get & update location" do
      #@response = MiniFB.get(@authentication.token, @authentication.uid)
      x = @person.get_location(@authentication, TestFBResponses::FULL)
      assert(@person.locations.first.name.is_a? String)

      number_of_locations1 = @person.locations.all.length
      x = @person.get_location(@authentication, TestFBResponses::FULL)
      number_of_locations2 = @person.locations.all.length
      assert_equal(number_of_locations1, number_of_locations2, "Ensure no duplicate locations")
    end

    should "get & update education history" do
      #real_response = MiniFB.get(@authentication.token, @authentication.uid)
      array_of_responses = [TestFBResponses::FULL, TestFBResponses::NO_CONCENTRATION, TestFBResponses::NO_YEAR, TestFBResponses::WITH_DEGREE, TestFBResponses::WITH_DEGREE, TestFBResponses::NO_EDUCATION]

      array_of_responses.each_with_index do |response, i|
        @response = response
        num_schools_on_fb = @response.try(:education).nil? ? 0 : @response.education.length
        @person.get_education_history(@authentication, @response)
        @person.reload
        number_of_schools1 = @person.education_histories.length

        name1 = @response.try(:education).present? ? @response.education.first.school.name : ""
        name2 = @person.education_histories.present? ? @person.education_histories.first.school_name : ""
        assert name1 == name2, "Assure name is properly written into DB"

        #do it again and ensure that no duplicate school entries are created
        @person.get_education_history(@authentication, @response)
        @person.reload
        number_of_schools2 = @person.education_histories.length

        assert number_of_schools1 == num_schools_on_fb, "Check number of schools on FB is equal to our DB after first method call"
        assert number_of_schools2 == num_schools_on_fb, "Check number of schools on FB is equal to our DB after second method call"

        @person.education_histories.destroy_all
      end
    end

    should "create from facebook and return a person" do
      data_hash = Hashie::Mash.new({first_name: "Matt", last_name: "Webb", email: "mattrw89@gmail.com"})
      person = Person.create_from_facebook(data_hash,@authentication, TestFBResponses::FULL)
      assert(person.locations.first.name.is_a? String)
      assert(person.education_histories.first.school_name.is_a? String)
      assert(['Male', 'Female'].include?(person.gender))
      assert_equal(person.email, "mattrw89@gmail.com", "See if person has correct email address")
    end

    should "get organizational permissions" do
      org = FactoryGirl.create(:organization)
      permissions = Array.new
      (1..3).each do |index|
        permissions << Permission.create!(name: "permission_#{index}", i18n: "permission_#{index}")
      end

      permissions.each do |permission|
        @person.organizational_permissions.create!(organization_id: org.id, permission_id: permission.id)
      end

      assert_equal(@person.assigned_organizational_permissions([org.id]).count, permissions.count)
    end

    should 'create and return vcard information of a person' do
      vcard = @person.vcard

      assert_not_nil(vcard.name)
      assert_equal(Vpim::Vcard, vcard.class)
    end

  end

  should "check if person is leader in an org" do
    user = FactoryGirl.create(:user_with_auxs)
    org = FactoryGirl.create(:organization)
    FactoryGirl.create(:organizational_permission, organization: org, person: user.person, permission: Permission.user)
    wat = nil
    assert user.person.user_in?(org)
    assert_equal false, user.person.user_in?(wat)
  end

  should "should find people by name or meail given wildcard strings" do
    org = FactoryGirl.create(:organization)
    user = FactoryGirl.create(:user_with_auxs)
    FactoryGirl.create(:organizational_permission, organization: org, person: user.person, permission: Permission.user)
    person1 = FactoryGirl.create(:person, first_name: "Neil Marion", last_name: "dela Cruz", email: "ndc@email.com")
    FactoryGirl.create(:organizational_permission, organization: org, person: person1, permission: Permission.user)
    person2 = FactoryGirl.create(:person, first_name: "Johnny", last_name: "English", email: "english@email.com")
    FactoryGirl.create(:organizational_permission, organization: org, person: person2, permission: Permission.no_permissions)
    person3 = FactoryGirl.create(:person, first_name: "Johnny", last_name: "Bravo", email: "bravo@email.com")
    FactoryGirl.create(:organizational_permission, organization: org, person: person3, permission: Permission.no_permissions)

    a = org.people.search_by_name_or_email("neil marion", org.id)
    assert_equal a.count, 1 # should be able to find a leader as well

    a = org.people.search_by_name_or_email("ndc", org.id)
    assert_equal a.count, 1 #should be able to find by an email address wildcard

    a = org.people.search_by_name_or_email("hnny", org.id) # as in Johnny
    assert_equal a.count, 2 #should be able to find contacts
  end

  context "merging 2 same admin persons in an org with an implied admin should" do
    should "not loose its admin abilities in that org" do
      user = FactoryGirl.create(:user_with_auxs)
      child_org = FactoryGirl.create(:organization, :name => "neilmarion", :parent => user.person.organizations.first, :show_sub_orgs => true)
      FactoryGirl.create(:organizational_permission, organization: child_org, person: user.person, permission: Permission.no_permissions)
      FactoryGirl.create(:organizational_permission, organization: child_org, person: user.person, permission: Permission.user)
      assert_equal user.person.admin_of_org_ids.sort, [user.person.organizations.first.id, child_org.id].sort
    end
  end

  should 'find an existing person based on name and phone number' do
    person = FactoryGirl.create(:person)
    person.phone_number = '555-555-5555'
    person.save!
    assert_equal(person, Person.find_existing_person_by_name_and_phone({first_name: person.first_name,
                                                                last_name: person.last_name,
                                                                number: '555-555-5555'}))
  end

  should 'find an existing person based on fb_uid' do
    person = FactoryGirl.create(:person, fb_uid: '5')

    assert_equal(person, Person.find_existing_person(Person.new(fb_uid: '5')))
  end
end