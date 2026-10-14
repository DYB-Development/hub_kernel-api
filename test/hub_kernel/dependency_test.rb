require "test_helper"

class DependencyTest < ActiveSupport::TestCase
  test "hub_kernel-api runs on hub_kernel-interface without loading hub_kernel" do
    assert_equal [ true, false ], [ Gem.loaded_specs.key?("hub_kernel-interface"), Gem.loaded_specs.key?("hub_kernel") ]
  end

  test "hub_kernel-api refuses a hub_kernel-interface older than the release holding the caller setting" do
    requirement = Gem.loaded_specs["hub_kernel-api"].dependencies.find { |dependency| dependency.name == "hub_kernel-interface" }.requirement

    assert_not requirement.satisfied_by?(Gem::Version.new("0.8.0"))
  end
end
