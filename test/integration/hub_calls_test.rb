require "test_helper"

class HubCallsTest < ActionDispatch::IntegrationTest
  test "a listed hub's exposed read answers a GET with the method's answer" do
    get "/hubs/shop/price_of", params: { item: "soap" }, headers: { "X-Person" => "sam", "X-Account" => "acme" }, as: :json

    assert_equal({ "answer" => "soap costs 3" }, response.parsed_body)
  end
end
