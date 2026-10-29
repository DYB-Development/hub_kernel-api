require "test_helper"

class HubKernel::Api::MajorVersionTest < ActiveSupport::TestCase
  test "a major is numbered by the first part of its full version" do
    assert_equal 2, HubKernel::Api::MajorVersion.new(version: "2.4.1").major
  end

  test "a host can mark a listed major retired" do
    assert_predicate HubKernel::Api::MajorVersion.new(version: "1.0.0", retired: true), :retired?
  end

  test "a host can mark a listed major deprecated" do
    assert_predicate HubKernel::Api::MajorVersion.new(version: "2.1.0", deprecated: true), :deprecated?
  end

  test "a host can give a deprecated major the date it was deprecated" do
    assert_equal Date.new(2026, 9, 30), HubKernel::Api::MajorVersion.new(version: "2.1.0", deprecated: true, deprecated_on: Date.new(2026, 9, 30)).deprecated_on
  end

  test "a host can give a deprecated major the date it stops being served" do
    assert_equal Date.new(2027, 3, 31), HubKernel::Api::MajorVersion.new(version: "2.1.0", deprecated: true, sunset: Date.new(2027, 3, 31)).sunset
  end
end
