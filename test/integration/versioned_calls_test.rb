require "test_helper"

class VersionedCallsTest < ActionDispatch::IntegrationTest
  test "a call naming a major in Accept-Version answers with that major's full version in Api-Version" do
    get "/hubs/shop/price_of", params: { item: "soap" }, headers: { "X-Person" => "sam", "X-Account" => "acme", "Accept-Version" => "2" }, as: :json

    assert_equal "2.1.0", response.headers["Api-Version"]
  end
end
