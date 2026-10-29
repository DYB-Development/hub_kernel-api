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
end
