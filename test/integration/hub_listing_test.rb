require "test_helper"

class HubListingTest < ActionDispatch::IntegrationTest
  test "a GET at a served hub's address lists each method's name, values and verb" do
    get "/hubs/shop", headers: { "X-Person" => "sam", "X-Account" => "acme" }, as: :json

    assert_equal [ { "name" => "price_of", "takes" => [ "item" ], "verb" => "GET" }, { "name" => "restock", "takes" => [ "item" ], "verb" => "POST" }, { "name" => "stock_of", "takes" => [ "item_id" ], "verb" => "GET" } ], response.parsed_body
  end
end
