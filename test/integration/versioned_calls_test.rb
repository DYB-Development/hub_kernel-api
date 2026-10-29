require "test_helper"

class VersionedCallsTest < ActionDispatch::IntegrationTest
  test "a call naming a major in Accept-Version answers with that major's full version in Api-Version" do
    get "/hubs/shop/price_of", params: { item: "soap" }, headers: { "X-Person" => "sam", "X-Account" => "acme", "Accept-Version" => "2" }, as: :json

    assert_equal "2.1.0", response.headers["Api-Version"]
  end

  test "a call sending no Accept-Version is answered at the oldest major served" do
    get "/hubs/shop/price_of", params: { item: "soap" }, headers: { "X-Person" => "sam", "X-Account" => "acme" }, as: :json

    assert_equal "1.0.0", response.headers["Api-Version"]
  end

  test "a call naming a major the host does not list is answered with status 406" do
    get "/hubs/shop/price_of", params: { item: "soap" }, headers: { "X-Person" => "sam", "X-Account" => "acme", "Accept-Version" => "7" }, as: :json

    assert_response :not_acceptable
  end
end
