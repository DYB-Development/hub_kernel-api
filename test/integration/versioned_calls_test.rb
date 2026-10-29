require "test_helper"

class VersionedCallsTest < ActionDispatch::IntegrationTest
  module Pantry
    extend HubKernel::Exposes

    exposes :shelf_of, takes: %i[item], writes: false, earlier_answers: {
      1 => ->(answer) { answer.transform_keys(row: :shelf) },
      2 => ->(answer) { answer.transform_keys(aisle: :row) }
    }

    def self.shelf_of(item:) = { item: item, aisle: 4 }
  end

  setup do
    @served = HubKernel::Api.hubs
    HubKernel::Api.hubs = [ Shop, { "pantry" => Pantry } ]
  end

  teardown { HubKernel::Api.hubs = @served }

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

  test "a call naming a major the host does not list is answered with an error naming the majors served" do
    get "/hubs/shop/price_of", params: { item: "soap" }, headers: { "X-Person" => "sam", "X-Account" => "acme", "Accept-Version" => "7" }, as: :json

    assert_equal({ "error" => "Major 7 is not served, the majors served are 1, 2 and 3" }, response.parsed_body)
  end

  test "a call's answer names Accept-Version in Vary" do
    get "/hubs/shop/price_of", params: { item: "soap" }, headers: { "X-Person" => "sam", "X-Account" => "acme", "Accept-Version" => "2" }, as: :json

    assert_equal "Accept-Version", response.headers["Vary"]
  end

  test "a call naming an older major answers through each earlier answer from the newest major down to it" do
    get "/hubs/pantry/shelf_of", params: { item: "soap" }, headers: { "X-Person" => "sam", "X-Account" => "acme", "Accept-Version" => "1" }, as: :json

    assert_equal({ "answer" => { "item" => "soap", "shelf" => 4 } }, response.parsed_body)
  end

  test "a call naming the newest major answers with the method's own answer" do
    get "/hubs/pantry/shelf_of", params: { item: "soap" }, headers: { "X-Person" => "sam", "X-Account" => "acme", "Accept-Version" => "3" }, as: :json

    assert_equal({ "answer" => { "item" => "soap", "aisle" => 4 } }, response.parsed_body)
  end
end
