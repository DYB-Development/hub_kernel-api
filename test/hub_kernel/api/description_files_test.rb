require "test_helper"
require "tmpdir"

class HubKernel::Api::DescriptionFilesTest < ActiveSupport::TestCase
  test "writing the description files writes one file for each listed major" do
    Dir.mktmpdir do |directory|
      HubKernel::Api::DescriptionFiles.write(directory)

      assert_equal [ "v1.json", "v2.json", "v3.json" ], Dir.children(directory).sort
    end
  end
end
