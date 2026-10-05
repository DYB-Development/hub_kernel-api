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
end
