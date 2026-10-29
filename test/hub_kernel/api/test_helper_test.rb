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

    exposes :bin_of, takes: %i[item], writes: false, answer_shape: { "type" => "object", "properties" => { "aisle" => { "type" => "integer" }, "item" => { "type" => "string" } } }

    def self.bin_of(item:) = { item: item, aisle: 4 }

    exposes :label_of, takes: %i[item], writes: false

    def self.label_of(item:) = item.upcase
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

  test "a failing assertion names the method and the major" do
    failure = assert_raises(Minitest::Assertion) { assert_answer_shape(Pantry, :shelf_of, { item: "flour" }, major: 3) }

    assert_equal "The answer to shelf_of at major 3 does not match its shape", failure.message.lines.first.chomp
  end

  test "a failing assertion names each place the answer differs from the shape, one to a line" do
    failure = assert_raises(Minitest::Assertion) { assert_answer_shape(Pantry, :bin_of, { item: 5, aisle: "four" }, major: 3) }

    assert_match %r{\n.*/aisle.*\n.*/item}, failure.message
  end

  test "the assertion used without json_schemer installed fails naming the gem to add" do
    define_singleton_method(:require) { |library| library == "json_schemer" ? raise(LoadError, "cannot load such file -- json_schemer") : super(library) }

    failure = assert_raises(LoadError) { assert_answer_shape(Pantry, :shelf_of, Pantry.shelf_of(item: "flour"), major: 3) }

    assert_equal 'assert_answer_shape needs the json_schemer gem, add gem "json_schemer" to the test group of your Gemfile', failure.message
  end

  test "the assertion fails naming a major the host does not list" do
    failure = assert_raises(Minitest::Assertion) { assert_answer_shape(Pantry, :shelf_of, Pantry.shelf_of(item: "flour"), major: 7) }

    assert_equal "The host lists no major 7 to check shelf_of at", failure.message
  end

  test "the assertion fails naming a method that declares no answer shape at the major" do
    failure = assert_raises(Minitest::Assertion) { assert_answer_shape(Pantry, :label_of, Pantry.label_of(item: "flour"), major: 3) }

    assert_equal "label_of declares no answer shape at major 3", failure.message
  end
end
