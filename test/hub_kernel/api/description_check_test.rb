require "test_helper"
require "tmpdir"
require "json"

class HubKernel::Api::DescriptionCheckTest < ActiveSupport::TestCase
  module Pantry
    extend HubKernel::Exposes

    exposes :shelf_of, takes: %i[item], writes: false, answer_shape: { "type" => "object", "properties" => { "aisle" => { "type" => "integer" }, "item" => { "type" => "string" } } }

    def self.shelf_of(item:) = { aisle: 4, item: item }
  end

  setup do
    @served = HubKernel::Api.hubs
    HubKernel::Api.hubs = [ { "pantry" => Pantry } ]
  end

  teardown { HubKernel::Api.hubs = @served }

  def committed(major) = JSON.parse(HubKernel::Api::Description.at(major).to_json)

  def commit(directory, major, description) = File.write(File.join(directory, "v#{major.major}.json"), JSON.pretty_generate(description))

  test "a major whose current description no longer holds a key its committed file holds is a removal naming the major, the method and the key" do
    major = HubKernel::Api.versions.second

    Dir.mktmpdir do |directory|
      description = committed(major)
      description["hubs"]["pantry"].first["answer_shape"]["properties"]["shelf"] = description["hubs"]["pantry"].first["answer_shape"]["properties"].delete("item")
      commit(directory, major, description)

      assert_equal [ "Major 2 removes or renames pantry.shelf_of.answer_shape.properties.shelf, which its committed file holds" ], HubKernel::Api::DescriptionCheck.removals(directory)
    end
  end

  test "a retired major's committed file is not compared" do
    listed = HubKernel::Api.versions
    retired = HubKernel::Api::MajorVersion.new(version: "1.0.0", retired: true)
    HubKernel::Api.versions = [ retired, HubKernel::Api::MajorVersion.new(version: "2.1.0") ]

    Dir.mktmpdir do |directory|
      description = committed(retired)
      description["hubs"]["pantry"].first["answer_shape"]["properties"]["shelf"] = { "type" => "string" }
      commit(directory, retired, description)

      assert_empty HubKernel::Api::DescriptionCheck.removals(directory)
    end
  ensure
    HubKernel::Api.versions = listed
  end

  test "checking the committed files raises an error naming each removal" do
    major = HubKernel::Api.versions.second

    Dir.mktmpdir do |directory|
      description = committed(major)
      description["hubs"]["pantry"].first["answer_shape"]["properties"]["shelf"] = { "type" => "string" }
      commit(directory, major, description)

      error = assert_raises(HubKernel::Api::BreakingChangeError) { HubKernel::Api::DescriptionCheck.check!(directory) }
      assert_equal "Major 2 removes or renames pantry.shelf_of.answer_shape.properties.shelf, which its committed file holds", error.message
    end
  end

  test "checking the committed files raises an error naming the major when it adds something without raising its minor" do
    major = HubKernel::Api.versions.second

    Dir.mktmpdir do |directory|
      description = committed(major)
      description["hubs"]["pantry"].first["takes"] = []
      commit(directory, major, description)

      error = assert_raises(HubKernel::Api::BreakingChangeError) { HubKernel::Api::DescriptionCheck.check!(directory) }
      assert_equal "Major 2 adds pantry.shelf_of.takes.item without raising its minor above 2.1.0", error.message
    end
  end

  test "checking the committed files passes when a major only adds things and raises its minor" do
    major = HubKernel::Api.versions.second

    Dir.mktmpdir do |directory|
      description = committed(major)
      description["version"] = "2.0.0"
      description["hubs"]["pantry"].first["takes"] = []
      commit(directory, major, description)

      assert_nothing_raised { HubKernel::Api::DescriptionCheck.check!(directory) }
    end
  end
end
