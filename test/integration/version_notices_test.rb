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

  test "an answer at the newest major carries none of the notice headers" do
    get "/hubs/shop/price_of", params: { item: "soap" }, headers: { "X-Person" => "sam", "X-Account" => "acme", "Accept-Version" => "3" }, as: :json

    assert_equal [ nil, nil, nil ], response.headers.values_at("Api-Newest-Version", "Deprecation", "Sunset")
  end

  test "an answer at a deprecated major carries a Deprecation header" do
    get "/hubs/shop/price_of", params: { item: "soap" }, headers: { "X-Person" => "sam", "X-Account" => "acme", "Accept-Version" => "2" }, as: :json

    assert_equal "true", response.headers["Deprecation"]
  end

  test "an answer at an older major that is not deprecated carries no Deprecation header" do
    get "/hubs/shop/price_of", params: { item: "soap" }, headers: { "X-Person" => "sam", "X-Account" => "acme", "Accept-Version" => "1" }, as: :json

    assert_nil response.headers["Deprecation"]
  end

  test "an answer at a deprecated major gives the date it stops being served in a Sunset header" do
    get "/hubs/shop/price_of", params: { item: "soap" }, headers: { "X-Person" => "sam", "X-Account" => "acme", "Accept-Version" => "2" }, as: :json

    assert_equal "Wed, 31 Mar 2027 00:00:00 GMT", response.headers["Sunset"]
  end

  test "a call at a deprecated major is answered end to end with its answer, its version and every notice header" do
    get "/hubs/shop/price_of", params: { item: "soap" }, headers: { "X-Person" => "sam", "X-Account" => "acme", "Accept-Version" => "2" }, as: :json

    assert_equal [ 200, { "answer" => "soap costs 3" }, "2.1.0", "3.0.2", "true", "Wed, 31 Mar 2027 00:00:00 GMT" ], [ response.status, response.parsed_body, *response.headers.values_at("Api-Version", "Api-Newest-Version", "Deprecation", "Sunset") ]
  end
end
