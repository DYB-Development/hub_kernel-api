require "test_helper"

class HubKernel::Api::DescriptionTest < ActiveSupport::TestCase
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

  test "a major's description gives its full version" do
    assert_equal "2.1.0", HubKernel::Api::Description.at(HubKernel::Api::MajorVersion.new(version: "2.1.0"))[:version]
  end

  test "a major's description holds every served hub's methods with their values, verb and answer shape at that major, whatever any caller may call" do
    refusing = HubKernel::Authz.check
    HubKernel::Authz.check = ->(*) { false }

    assert_equal({
      "shop" => [ { name: :price_of, takes: [ :item ], verb: "GET" }, { name: :restock, takes: [ :item ], verb: "POST" }, { name: :stock_of, takes: [ :item_id ], verb: "GET" } ],
      "pantry" => [ { name: :shelf_of, takes: [ :item ], verb: "GET", answer_shape: { "type" => "object", "required" => [ "row" ] } }, { name: :restock, takes: [ :item ], verb: "POST" } ]
    }, HubKernel::Api::Description.at(HubKernel::Api::MajorVersion.new(version: "1.0.0"))[:hubs])
  ensure
    HubKernel::Authz.check = refusing
  end
end
