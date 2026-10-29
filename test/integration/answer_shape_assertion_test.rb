require "test_helper"
require "hub_kernel/api/test_helper"

class AnswerShapeAssertionTest < ActionDispatch::IntegrationTest
  include HubKernel::Api::TestHelper

  module Pantry
    extend HubKernel::Exposes

    exposes :shelf_of, takes: %i[item], writes: false, answer_shape: { "type" => "object", "required" => [ "item", "aisle" ], "properties" => { "aisle" => { "type" => "integer" } } }

    def self.shelf_of(item:) = { item: item, aisle: 4 }
  end

  setup do
    @served = HubKernel::Api.hubs
    HubKernel::Api.hubs = [ { "pantry" => Pantry } ]
  end

  teardown { HubKernel::Api.hubs = @served }

  test "an answer from a call through the engine at the newest major matches the shape the assertion reads for that major" do
    get "/hubs/pantry/shelf_of", params: { item: "flour" }, headers: { "X-Person" => "sam", "X-Account" => "acme", "Accept-Version" => "3" }, as: :json

    assert_answer_shape(Pantry, :shelf_of, response.parsed_body["answer"], major: 3)
  end
end
