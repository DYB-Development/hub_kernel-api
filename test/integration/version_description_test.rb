require "test_helper"

class VersionDescriptionTest < ActionDispatch::IntegrationTest
  module Pantry
    extend HubKernel::Exposes

    exposes :shelf_of, takes: %i[item], writes: false, answer_shape: { "type" => "object", "required" => [ "aisle" ] }, earlier_answers: {
      2 => { translation: ->(answer) { answer.transform_keys(aisle: :row) }, answer_shape: { "type" => "object", "required" => [ "row" ] } }
    }

    def self.shelf_of(item:) = { item: item, aisle: 4 }

    exposes :restock, takes: %i[item], writes: true

    def self.restock(item:) = "#{item} restocked"
  end

  setup do
    @served = HubKernel::Api.hubs
    HubKernel::Api.hubs = [ Shop, { "pantry" => Pantry } ]
  end

  teardown { HubKernel::Api.hubs = @served }

  test "a GET at the API's root address lists every served hub's methods with their values, verb and answer shape at the major named" do
    get "/hubs", headers: { "X-Person" => "sam", "X-Account" => "acme", "Accept-Version" => "2" }, as: :json

    assert_equal({
      "shop" => [ { "name" => "price_of", "takes" => [ "item" ], "verb" => "GET" }, { "name" => "restock", "takes" => [ "item" ], "verb" => "POST" }, { "name" => "stock_of", "takes" => [ "item_id" ], "verb" => "GET" } ],
      "pantry" => [ { "name" => "shelf_of", "takes" => [ "item" ], "verb" => "GET", "answer_shape" => { "type" => "object", "required" => [ "row" ] } }, { "name" => "restock", "takes" => [ "item" ], "verb" => "POST" } ]
    }, response.parsed_body["hubs"])
  end

  test "the listing at the API's root address gives the full version of the major it describes" do
    get "/hubs", headers: { "X-Person" => "sam", "X-Account" => "acme", "Accept-Version" => "2" }, as: :json

    assert_equal "2.1.0", response.parsed_body["version"]
  end

  test "the listing at the API's root address from a host that lists no majors gives no version" do
    listed = HubKernel::Api.versions
    HubKernel::Api.versions = []

    get "/hubs", headers: { "X-Person" => "sam", "X-Account" => "acme" }, as: :json

    assert_equal [ "hubs" ], response.parsed_body.keys
  ensure
    HubKernel::Api.versions = listed
  end

  test "a GET at the API's root address at an older major is answered end to end with only the methods the caller may call and its version headers" do
    allowing = HubKernel::Authz.check
    HubKernel::Authz.check = ->(_person, action, _account) { action == "pantry:shelf_of" }

    get "/hubs", headers: { "X-Person" => "sam", "X-Account" => "acme", "Accept-Version" => "1" }, as: :json

    assert_equal [ 200, { "version" => "1.0.0", "hubs" => { "shop" => [], "pantry" => [ { "name" => "shelf_of", "takes" => [ "item" ], "verb" => "GET", "answer_shape" => { "type" => "object", "required" => [ "row" ] } } ] } }, "1.0.0", "Accept-Version" ], [ response.status, response.parsed_body, response.headers["Api-Version"], response.headers["Vary"] ]
  ensure
    HubKernel::Authz.check = allowing
  end

  test "the listing at the API's root address from a host that lists no majors ignores a major named in Accept-Version" do
    listed = HubKernel::Api.versions
    HubKernel::Api.versions = []

    get "/hubs", headers: { "X-Person" => "sam", "X-Account" => "acme", "Accept-Version" => "1" }, as: :json

    assert_response :ok
  ensure
    HubKernel::Api.versions = listed
  end
end
