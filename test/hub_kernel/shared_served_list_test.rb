require "test_helper"

class HubKernel::SharedServedListTest < ActiveSupport::TestCase
  setup { @served = HubKernel::Interface.hubs }
  teardown { HubKernel::Interface.hubs = @served }

  test "hub_kernel-api's hubs setting writes to the host's one served list" do
    HubKernel::Api.hubs = [ Shop, { "store" => Shop } ]

    assert_equal [ Shop, { "store" => Shop } ], HubKernel::Interface.hubs
  end
end
