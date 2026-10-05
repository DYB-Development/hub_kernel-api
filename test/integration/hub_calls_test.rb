require "test_helper"

class HubCallsTest < ActionDispatch::IntegrationTest
  test "a listed hub's exposed read answers a GET with the method's answer" do
    get "/hubs/shop/price_of", params: { item: "soap" }, headers: { "X-Person" => "sam", "X-Account" => "acme" }, as: :json

    assert_equal({ "answer" => "soap costs 3" }, response.parsed_body)
  end

  test "a write asked for with GET is answered as not found" do
    get "/hubs/shop/restock", params: { item: "soap" }, headers: { "X-Person" => "sam", "X-Account" => "acme" }, as: :json

    assert_equal({ "error" => "Not found" }, response.parsed_body)
  end

  test "a read asked for with POST is answered as not found" do
    post "/hubs/shop/price_of", params: { item: "soap" }, headers: { "X-Person" => "sam", "X-Account" => "acme" }, as: :json

    assert_equal({ "error" => "Not found" }, response.parsed_body)
  end

  test "a hub that is not listed is answered with status 404" do
    get "/hubs/bakery/price_of", params: { item: "bread" }, headers: { "X-Person" => "sam", "X-Account" => "acme" }, as: :json

    assert_response :not_found
  end

  test "a method the hub does not expose is answered as not found" do
    get "/hubs/shop/close_shop", headers: { "X-Person" => "sam", "X-Account" => "acme" }, as: :json

    assert_equal({ "error" => "Not found" }, response.parsed_body)
  end

  test "a call the host's permission check refuses is answered as not found" do
    allowing = HubKernel::Authz.check
    HubKernel::Authz.check = ->(*) { false }

    get "/hubs/shop/price_of", params: { item: "soap" }, headers: { "X-Person" => "sam", "X-Account" => "acme" }, as: :json

    assert_equal({ "error" => "Not found" }, response.parsed_body)
  ensure
    HubKernel::Authz.check = allowing
  end

  test "a hub's refusal is answered with its reason under error" do
    post "/hubs/shop/restock", params: { item: "ice" }, headers: { "X-Person" => "sam", "X-Account" => "acme" }, as: :json

    assert_equal({ "error" => "The ice shelf is full" }, response.parsed_body)
  end

  test "a call missing a value the method requires is answered with status 422" do
    get "/hubs/shop/price_of", headers: { "X-Person" => "sam", "X-Account" => "acme" }, as: :json

    assert_response :unprocessable_content
  end

  test "a call naming a record that does not exist is answered with the record and the id" do
    get "/hubs/shop/stock_of", params: { item_id: 9 }, headers: { "X-Person" => "sam", "X-Account" => "acme" }, as: :json

    assert_equal({ "error" => "No item has the id 9" }, response.parsed_body)
  end

  test "a caller the host's base controller refuses is refused before any hub method runs" do
    get "/hubs/shop/price_of", params: { item: "soap" }, as: :json

    assert_response :unauthorized
  end

  test "every call is made for the person and the account the host's methods give" do
    allowing, asked = HubKernel::Authz.check, []
    HubKernel::Authz.check = ->(person, _action, account) { asked << [ person, account ] && true }

    get "/hubs/shop/price_of", params: { item: "soap" }, headers: { "X-Person" => "sam", "X-Account" => "acme" }, as: :json

    assert_equal [ [ "sam", "acme" ] ], asked
  ensure
    HubKernel::Authz.check = allowing
  end
end
