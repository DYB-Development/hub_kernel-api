require "test_helper"

class AnswerShapesTest < ActionDispatch::IntegrationTest
  module Pantry
    extend HubKernel::Exposes

    exposes :shelf_of, takes: %i[item], writes: false, answer_shape: { "type" => "object", "required" => [ "aisle" ] }, earlier_answers: {
      1 => { translation: ->(answer) { answer.transform_keys(row: :shelf) }, answer_shape: { "type" => "object", "required" => [ "shelf" ] } },
      2 => { translation: ->(answer) { answer.transform_keys(aisle: :row) }, answer_shape: { "type" => "object", "required" => [ "row" ] } }
    }

    def self.shelf_of(item:) = { item: item, aisle: 4 }

    exposes :label_of, takes: %i[item], writes: false

    def self.label_of(item:) = item.upcase

    exposes :aisle_of, takes: %i[item], writes: false, answer_shape: { "type" => "integer" }, earlier_answers: {
      2 => { translation: ->(answer) { answer.to_s }, answer_shape: { "type" => "string" } }
    }

    def self.aisle_of(item:) = 4

    exposes :bin_of, takes: %i[item], writes: false, answer_shape: { "type" => "integer" }, earlier_answers: {
      1 => ->(answer) { answer.to_s }
    }

    def self.bin_of(item:) = 9
  end

  setup do
    @served = HubKernel::Api.hubs
    HubKernel::Api.hubs = [ { "pantry" => Pantry } ]
  end

  teardown { HubKernel::Api.hubs = @served }

  test "a hub listing at the newest major shows a method's own answer shape" do
    get "/hubs/pantry", headers: { "X-Person" => "sam", "X-Account" => "acme", "Accept-Version" => "3" }, as: :json

    assert_equal({ "type" => "object", "required" => [ "aisle" ] }, response.parsed_body.first["answer_shape"])
  end

  test "a hub listing shows a method that declares no answer shape with no shape" do
    get "/hubs/pantry", headers: { "X-Person" => "sam", "X-Account" => "acme", "Accept-Version" => "3" }, as: :json

    assert_equal({ "name" => "label_of", "takes" => [ "item" ], "verb" => "GET" }, response.parsed_body.find { |listed| listed["name"] == "label_of" })
  end

  test "a hub listing asked with no Accept-Version shows each method's answer shape at the oldest major served" do
    get "/hubs/pantry", headers: { "X-Person" => "sam", "X-Account" => "acme" }, as: :json

    assert_equal({ "type" => "object", "required" => [ "shelf" ] }, response.parsed_body.first["answer_shape"])
  end

  test "a hub listing at an older major with no earlier answer declared for it shows the answer shape at the major after it" do
    get "/hubs/pantry", headers: { "X-Person" => "sam", "X-Account" => "acme", "Accept-Version" => "1" }, as: :json

    assert_equal({ "type" => "string" }, response.parsed_body.find { |listed| listed["name"] == "aisle_of" }["answer_shape"])
  end

  test "a hub listing at an older major whose earlier answer declares no shape shows that method with no shape" do
    get "/hubs/pantry", headers: { "X-Person" => "sam", "X-Account" => "acme", "Accept-Version" => "1" }, as: :json

    assert_equal({ "name" => "bin_of", "takes" => [ "item" ], "verb" => "GET" }, response.parsed_body.find { |listed| listed["name"] == "bin_of" })
  end
end
