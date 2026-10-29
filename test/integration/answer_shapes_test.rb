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
end
