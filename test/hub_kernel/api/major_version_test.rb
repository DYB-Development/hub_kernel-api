require "test_helper"

class HubKernel::Api::MajorVersionTest < ActiveSupport::TestCase
  test "a major is numbered by the first part of its full version" do
    assert_equal 2, HubKernel::Api::MajorVersion.new(version: "2.4.1").major
  end
end
