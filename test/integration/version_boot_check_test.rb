require "test_helper"

class VersionBootCheckTest < ActiveSupport::TestCase
  setup { @listed = HubKernel::Api.versions }

  teardown do
    HubKernel::Api.versions = @listed
    Rails.application.reloader.prepare!
  end

  test "a host whose version list holds a mistake refuses to start, naming it" do
    HubKernel::Api.versions = [ HubKernel::Api::MajorVersion.new(version: "1.0.0", deprecated: true, deprecated_on: Date.new(2026, 9, 30)), HubKernel::Api::MajorVersion.new(version: "2.1.0") ]

    assert_raises(HubKernel::Api::UnservableHubError, match: "Major 1 is deprecated with no sunset: date it stops being served") { Rails.application.reloader.prepare! }
  end
end
