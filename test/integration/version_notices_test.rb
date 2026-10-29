require "test_helper"

class VersionNoticesTest < ActionDispatch::IntegrationTest
  setup do
    @listed = HubKernel::Api.versions
    HubKernel::Api.versions = [ HubKernel::Api::MajorVersion.new(version: "1.0.0"), HubKernel::Api::MajorVersion.new(version: "2.1.0", deprecated: true, sunset: Date.new(2027, 3, 31)), HubKernel::Api::MajorVersion.new(version: "3.0.2") ]
  end

  teardown { HubKernel::Api.versions = @listed }

  test "an answer at a major older than the newest gives the newest major's full version in Api-Newest-Version" do
    get "/hubs/shop/price_of", params: { item: "soap" }, headers: { "X-Person" => "sam", "X-Account" => "acme", "Accept-Version" => "1" }, as: :json

    assert_equal "3.0.2", response.headers["Api-Newest-Version"]
  end
end
