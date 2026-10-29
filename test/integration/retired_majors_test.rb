require "test_helper"

class RetiredMajorsTest < ActionDispatch::IntegrationTest
  setup do
    @listed = HubKernel::Api.versions
    HubKernel::Api.versions = [ HubKernel::Api::MajorVersion.new(version: "1.0.0", retired: true), HubKernel::Api::MajorVersion.new(version: "2.1.0"), HubKernel::Api::MajorVersion.new(version: "3.0.2") ]
  end

  teardown { HubKernel::Api.versions = @listed }

  test "a call naming a retired major is answered with status 410" do
    get "/hubs/shop/price_of", params: { item: "soap" }, headers: { "X-Person" => "sam", "X-Account" => "acme", "Accept-Version" => "1" }, as: :json

    assert_response :gone
  end

  test "a call naming a retired major is answered with an error saying that major is no longer served and naming the newest major" do
    get "/hubs/shop/price_of", params: { item: "soap" }, headers: { "X-Person" => "sam", "X-Account" => "acme", "Accept-Version" => "1" }, as: :json

    assert_equal({ "error" => "Major 1 is no longer served, the newest major is 3" }, response.parsed_body)
  end

  test "a GET at a hub's address naming a retired major is answered with status 410 and the retired major's error" do
    get "/hubs/shop", headers: { "X-Person" => "sam", "X-Account" => "acme", "Accept-Version" => "1" }, as: :json

    assert_equal [ 410, { "error" => "Major 1 is no longer served, the newest major is 3" } ], [ response.status, response.parsed_body ]
  end

  test "a call naming a retired major is refused the same way when the hub it names is not served" do
    get "/hubs/pantry/shelf_of", params: { item: "soap" }, headers: { "X-Person" => "sam", "X-Account" => "acme", "Accept-Version" => "1" }, as: :json

    assert_equal [ 410, { "error" => "Major 1 is no longer served, the newest major is 3" } ], [ response.status, response.parsed_body ]
  end

  test "a call sending no Accept-Version is answered at the oldest major that is not retired" do
    get "/hubs/shop/price_of", params: { item: "soap" }, headers: { "X-Person" => "sam", "X-Account" => "acme" }, as: :json

    assert_equal "2.1.0", response.headers["Api-Version"]
  end

  test "a write at a retired major is refused end to end with status 410, the reason, and no Api-Version" do
    post "/hubs/shop/restock", params: { item: "soap" }, headers: { "X-Person" => "sam", "X-Account" => "acme", "Accept-Version" => "1" }, as: :json

    assert_equal [ 410, { "error" => "Major 1 is no longer served, the newest major is 3" }, nil ], [ response.status, response.parsed_body, response.headers["Api-Version"] ]
  end
end
