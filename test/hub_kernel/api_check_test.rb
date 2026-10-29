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

  module Larder
    extend HubKernel::Exposes

    exposes :count_jars, takes: [], writes: false, earlier_answers: { 7 => ->(answer) { answer } }

    def self.count_jars = 3
  end

  setup do
    @served = HubKernel::Api.hubs
    @listed = HubKernel::Api.versions
    HubKernel::Api.versions = [ HubKernel::Api::MajorVersion.new(version: "1.0.0"), HubKernel::Api::MajorVersion.new(version: "2.1.0") ]
  end

  teardown do
    HubKernel::Api.hubs = @served
    HubKernel::Api.versions = @listed
  end

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

  test "an earlier answer declared for a major the host does not list stops the app and is named" do
    HubKernel::Api.hubs = [ Larder ]

    assert_raises(HubKernel::Api::UnservableHubError, match: "HubKernel::ApiCheckTest::Larder declares an earlier answer to count_jars for major 7, which the host does not list") { HubKernel::Api.check! }
  end
end
