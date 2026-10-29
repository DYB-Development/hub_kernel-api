require "test_helper"
require "hub_kernel/api/test_helper"

class HubKernel::Api::TestHelperTest < ActiveSupport::TestCase
  include HubKernel::Api::TestHelper

  module Pantry
    extend HubKernel::Exposes

    exposes :shelf_of, takes: %i[item], writes: false, answer_shape: { "type" => "object", "required" => [ "aisle" ] }, earlier_answers: {
      1 => { translation: ->(answer) { answer.transform_keys(aisle: :shelf) }, answer_shape: { "type" => "object", "required" => [ "shelf" ] } }
    }

    def self.shelf_of(item:) = { item: item, aisle: 4 }
  end

  test "the assertion fails when a method's answer does not match its shape at the major" do
    assert_raises(Minitest::Assertion) { assert_answer_shape(Pantry, :shelf_of, { item: "flour" }, major: 3) }
  end

  test "the assertion passes when a method's own answer matches its shape at the newest major" do
    assert_answer_shape(Pantry, :shelf_of, Pantry.shelf_of(item: "flour"), major: 3)
  end

  test "the assertion passes when a method's own answer translated down to an older major matches that major's shape" do
    assert_answer_shape(Pantry, :shelf_of, Pantry.shelf_of(item: "flour"), major: 1)
  end
end
