require "test_helper"

class HubKernel::Api::DescriptionTest < ActiveSupport::TestCase
  test "a major's description gives its full version" do
    assert_equal "2.1.0", HubKernel::Api::Description.at(HubKernel::Api::MajorVersion.new(version: "2.1.0"))[:version]
  end
end
