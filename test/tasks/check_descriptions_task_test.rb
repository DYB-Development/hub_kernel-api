require "test_helper"
require "open3"
require "json"
require "fileutils"

class CheckDescriptionsTaskTest < ActiveSupport::TestCase
  teardown { FileUtils.rm_rf(Rails.root.join("api_descriptions")) }

  test "a host's CI run of the committed-description task fails naming a method its major's committed file holds and its current description does not" do
    description = JSON.parse(HubKernel::Api::Description.at(HubKernel::Api.versions.second).to_json)
    description["hubs"]["shop"] << { "name" => "discount_of", "takes" => [ "item" ], "verb" => "GET" }
    FileUtils.mkdir_p(Rails.root.join("api_descriptions"))
    File.write(Rails.root.join("api_descriptions", "v2.json"), JSON.pretty_generate(description))

    output, _status = Open3.capture2e("bin/rails", "hub_kernel_api:check_descriptions", chdir: Rails.root.to_s)

    assert_includes output, "Major 2 removes or renames shop.discount_of, which its committed file holds"
  end
end
