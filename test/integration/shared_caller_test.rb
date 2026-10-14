require "test_helper"

class SharedCallerTest < ActionDispatch::IntegrationTest
  setup do
    @own = [ HubKernel::Api.person_method, HubKernel::Api.account_method ]
    @shared = [ HubKernel::Interface.person_method, HubKernel::Interface.account_method ]
    @allowing = HubKernel::Authz.check
  end

  teardown do
    HubKernel::Api.person_method, HubKernel::Api.account_method = @own
    HubKernel::Interface.person_method, HubKernel::Interface.account_method = @shared
    HubKernel::Authz.check = @allowing
  end

  test "a call names its caller with the shared person and account methods when the JSON API's own are not set" do
    HubKernel::Api.person_method, HubKernel::Api.account_method = nil, nil
    HubKernel::Interface.person_method, HubKernel::Interface.account_method = :current_person, :current_account
    asked = []
    HubKernel::Authz.check = ->(person, _action, account) { asked << [ person, account ] && true }

    get "/hubs/shop/price_of", params: { item: "soap" }, headers: { "X-Person" => "sam", "X-Account" => "acme" }, as: :json

    assert_equal [ [ "sam", "acme" ] ], asked
  end

  test "the JSON API's own person and account methods are used instead of the shared ones when set" do
    HubKernel::Api.person_method, HubKernel::Api.account_method = :current_person, :current_account
    HubKernel::Interface.person_method, HubKernel::Interface.account_method = :current_account, :current_person
    asked = []
    HubKernel::Authz.check = ->(person, _action, account) { asked << [ person, account ] && true }

    get "/hubs/shop/price_of", params: { item: "soap" }, headers: { "X-Person" => "sam", "X-Account" => "acme" }, as: :json

    assert_equal [ [ "sam", "acme" ] ], asked
  end
end
