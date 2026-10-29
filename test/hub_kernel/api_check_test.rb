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

  module Spicerack
    extend HubKernel::Exposes

    exposes :count_spices, takes: [], writes: false, earlier_answers: { 2 => ->(answer) { answer } }

    def self.count_spices = 9
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

  test "an earlier answer declared for the newest major stops the app and is named" do
    HubKernel::Api.hubs = [ Spicerack ]

    assert_raises(HubKernel::Api::UnservableHubError, match: "HubKernel::ApiCheckTest::Spicerack declares an earlier answer to count_spices for major 2, the newest major, which has no newer answer to translate from") { HubKernel::Api.check! }
  end

  test "a listed version not in major.minor.patch form stops the app and is named" do
    HubKernel::Api.versions = [ HubKernel::Api::MajorVersion.new(version: "1.0.0"), HubKernel::Api::MajorVersion.new(version: "2.1") ]

    assert_raises(HubKernel::Api::UnservableHubError, match: "The listed version 2.1 is not in major.minor.patch form") { HubKernel::Api.check! }
  end

  test "a major the host lists twice stops the app and is named" do
    HubKernel::Api.versions = [ HubKernel::Api::MajorVersion.new(version: "1.0.0"), HubKernel::Api::MajorVersion.new(version: "1.2.0"), HubKernel::Api::MajorVersion.new(version: "2.1.0") ]

    assert_raises(HubKernel::Api::UnservableHubError, match: "Major 1 is listed more than once") { HubKernel::Api.check! }
  end

  test "a deprecated major with no date it stops being served stops the app and is named" do
    HubKernel::Api.versions = [ HubKernel::Api::MajorVersion.new(version: "1.0.0", deprecated: true, deprecated_on: Date.new(2026, 9, 30)), HubKernel::Api::MajorVersion.new(version: "2.1.0") ]

    assert_raises(HubKernel::Api::UnservableHubError, match: "Major 1 is deprecated with no sunset: date it stops being served") { HubKernel::Api.check! }
  end

  test "a version list in which every major is retired stops the app and is named" do
    HubKernel::Api.versions = [ HubKernel::Api::MajorVersion.new(version: "1.0.0", retired: true), HubKernel::Api::MajorVersion.new(version: "2.1.0", retired: true) ]

    assert_raises(HubKernel::Api::UnservableHubError, match: "Every listed major is retired, so a call with no Accept-Version has no major to be answered at") { HubKernel::Api.check! }
  end

  test "problems in the served list and in the versions stop the app together in one error naming each" do
    HubKernel::Api.hubs = [ Bakery, Larder ]

    assert_raises(HubKernel::Api::UnservableHubError, match: "HubKernel::ApiCheckTest::Bakery exposes no methods to serve\nHubKernel::ApiCheckTest::Larder declares an earlier answer to count_jars for major 7, which the host does not list") { HubKernel::Api.check! }
  end

  test "a deprecated_on: date given as something other than a Date stops the app and is named" do
    HubKernel::Api.versions = [ HubKernel::Api::MajorVersion.new(version: "1.0.0", deprecated: true, deprecated_on: "2026-09-30", sunset: Date.new(2027, 3, 31)), HubKernel::Api::MajorVersion.new(version: "2.1.0") ]

    assert_raises(HubKernel::Api::UnservableHubError, match: 'Major 1 gives deprecated_on: as "2026-09-30", which is not a Date') { HubKernel::Api.check! }
  end

  test "a sunset: date given as something other than a Date stops the app and is named" do
    HubKernel::Api.versions = [ HubKernel::Api::MajorVersion.new(version: "1.0.0", deprecated: true, deprecated_on: Date.new(2026, 9, 30), sunset: "2027-03-31"), HubKernel::Api::MajorVersion.new(version: "2.1.0") ]

    assert_raises(HubKernel::Api::UnservableHubError, match: 'Major 1 gives sunset: as "2027-03-31", which is not a Date') { HubKernel::Api.check! }
  end
end
