require 'test_helper'

class Api::UserControllerTest < ActionController::TestCase
  context "a user action" do
    setup do
      @user = FactoryGirl.create(:user_with_auxs)
      @access_token = FactoryGirl.create(:access_token)
      @access_token.identity = @user.id
      @access_token.client_id = 1
    end
  end
end