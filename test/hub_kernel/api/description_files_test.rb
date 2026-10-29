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
end
