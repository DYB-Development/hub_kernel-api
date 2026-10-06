require "test_helper"

class HubKernel::ApiCheckTest < ActiveSupport::TestCase
  module Bakery
  end

  setup { @served = HubKernel::Api.hubs }
  teardown { HubKernel::Api.hubs = @served }

  test "a served entry with no exposed list stops the app and is named" do
    HubKernel::Api.hubs = [ Bakery ]

    assert_raises(HubKernel::Api::UnservableHubError, match: "HubKernel::ApiCheckTest::Bakery exposes no methods to serve") { HubKernel::Api.check! }
  end
end
