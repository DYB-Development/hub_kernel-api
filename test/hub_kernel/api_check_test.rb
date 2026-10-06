require "test_helper"

class HubKernel::ApiCheckTest < ActiveSupport::TestCase
  module Bakery
  end

  module Pantry
    extend HubKernel::Exposes
  end

  module Cellar
    extend HubKernel::Exposes

    exposes :count_bottles, takes: [], writes: false
  end

  setup { @served = HubKernel::Api.hubs }
  teardown { HubKernel::Api.hubs = @served }

  test "a served entry with no exposed list stops the app and is named" do
    HubKernel::Api.hubs = [ Bakery ]

    assert_raises(HubKernel::Api::UnservableHubError, match: "HubKernel::ApiCheckTest::Bakery exposes no methods to serve") { HubKernel::Api.check! }
  end

  test "two served hubs sharing an address name stop the app and are named with the name" do
    HubKernel::Api.hubs = [ Shop, { "shop" => Pantry } ]

    assert_raises(HubKernel::Api::UnservableHubError, match: "Shop and HubKernel::ApiCheckTest::Pantry both answer at shop") { HubKernel::Api.check! }
  end

  test "a served hub whose exposed list has a problem stops the app and the problem is named" do
    HubKernel::Api.hubs = [ Cellar ]

    assert_raises(HubKernel::Api::UnservableHubError, match: "Cellar exposes count_bottles, which it has no method for") { HubKernel::Api.check! }
  end

  test "a correct served-hub list starts" do
    HubKernel::Api.hubs = [ Shop, { "store" => Shop } ]

    assert_nothing_raised { HubKernel::Api.check! }
  end
end
