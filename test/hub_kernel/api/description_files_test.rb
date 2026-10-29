require "test_helper"
require "tmpdir"
require "json"

class HubKernel::Api::DescriptionFilesTest < ActiveSupport::TestCase
  test "writing the description files writes one file for each listed major" do
    Dir.mktmpdir do |directory|
      HubKernel::Api::DescriptionFiles.write(directory)

      assert_equal [ "v1.json", "v2.json", "v3.json" ], Dir.children(directory).sort
    end
  end

  test "a major's description file holds that major's description as JSON" do
    Dir.mktmpdir do |directory|
      HubKernel::Api::DescriptionFiles.write(directory)

      assert_equal JSON.parse(HubKernel::Api::Description.at(HubKernel::Api.versions.second).to_json), JSON.parse(File.read(File.join(directory, "v2.json")))
    end
  end

  test "writing the description files twice with no change to any hub writes identical files" do
    Dir.mktmpdir do |directory|
      HubKernel::Api::DescriptionFiles.write(directory)
      first = File.read(File.join(directory, "v2.json"))
      HubKernel::Api::DescriptionFiles.write(directory)

      assert_equal first, File.read(File.join(directory, "v2.json"))
    end
  end

  test "writing the description files writes no file for a retired major" do
    listed = HubKernel::Api.versions
    HubKernel::Api.versions = [ HubKernel::Api::MajorVersion.new(version: "1.0.0", retired: true), HubKernel::Api::MajorVersion.new(version: "2.1.0") ]

    Dir.mktmpdir do |directory|
      HubKernel::Api::DescriptionFiles.write(directory)

      assert_equal [ "v2.json" ], Dir.children(directory)
    end
  ensure
    HubKernel::Api.versions = listed
  end

  test "writing the description files leaves a major's file as it was when its current description removes something the file holds" do
    Dir.mktmpdir do |directory|
      description = JSON.parse(HubKernel::Api::Description.at(HubKernel::Api.versions.second).to_json)
      description["hubs"]["shop"] << { "name" => "discount_of", "takes" => [ "item" ], "verb" => "GET" }
      File.write(File.join(directory, "v2.json"), JSON.pretty_generate(description))

      assert_raises(HubKernel::Api::BreakingChangeError) { HubKernel::Api::DescriptionFiles.write(directory) }
      assert_equal JSON.pretty_generate(description), File.read(File.join(directory, "v2.json"))
    end
  end

  test "the refused description files name each removal" do
    Dir.mktmpdir do |directory|
      description = JSON.parse(HubKernel::Api::Description.at(HubKernel::Api.versions.second).to_json)
      description["hubs"]["shop"] << { "name" => "discount_of", "takes" => [ "item" ], "verb" => "GET" }
      description["hubs"]["shop"].first["takes"] << "size"
      File.write(File.join(directory, "v2.json"), JSON.pretty_generate(description))

      error = assert_raises(HubKernel::Api::BreakingChangeError) { HubKernel::Api::DescriptionFiles.write(directory) }
      assert_equal "Major 2 removes or renames shop.price_of.takes.size, which its committed file holds\nMajor 2 removes or renames shop.discount_of, which its committed file holds", error.message
    end
  end

  test "writing the description files rewrites a major's file when its current description only adds to it under a raised minor" do
    Dir.mktmpdir do |directory|
      description = JSON.parse(HubKernel::Api::Description.at(HubKernel::Api.versions.second).to_json)
      description["version"] = "2.0.0"
      description["hubs"]["shop"].first["takes"] = []
      File.write(File.join(directory, "v2.json"), JSON.pretty_generate(description))

      HubKernel::Api::DescriptionFiles.write(directory)

      assert_equal JSON.pretty_generate(HubKernel::Api::Description.at(HubKernel::Api.versions.second)), File.read(File.join(directory, "v2.json"))
    end
  end
end
