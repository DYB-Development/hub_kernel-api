require "test_helper"

class HubListingTest < ActionDispatch::IntegrationTest
  test "a GET at a served hub's address lists each method's name, values and verb" do
    get "/hubs/shop", headers: { "X-Person" => "sam", "X-Account" => "acme" }, as: :json

    assert_equal [ { "name" => "price_of", "takes" => [ "item" ], "verb" => "GET" }, { "name" => "restock", "takes" => [ "item" ], "verb" => "POST" }, { "name" => "stock_of", "takes" => [ "item_id" ], "verb" => "GET" } ], response.parsed_body
  end

  test "a method the host's permission check refuses the caller is not shown" do
    allowing = HubKernel::Authz.check
    HubKernel::Authz.check = ->(_person, action, _account) { action == "shop:price_of" }

    get "/hubs/shop", headers: { "X-Person" => "sam", "X-Account" => "acme" }, as: :json

    assert_equal [ "price_of" ], response.parsed_body.pluck("name")
  ensure
    HubKernel::Authz.check = allowing
  end

  test "a hub that is not served is answered as not found" do
    get "/hubs/bakery", headers: { "X-Person" => "sam", "X-Account" => "acme" }, as: :json

    assert_equal({ "error" => "Not found" }, response.parsed_body)
  end
end
