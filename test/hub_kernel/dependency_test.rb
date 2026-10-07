require "test_helper"

class DependencyTest < ActiveSupport::TestCase
  test "hub_kernel-api runs on hub_kernel-interface without loading hub_kernel" do
    assert_equal [ true, false ], [ Gem.loaded_specs.key?("hub_kernel-interface"), Gem.loaded_specs.key?("hub_kernel") ]
  end
end
