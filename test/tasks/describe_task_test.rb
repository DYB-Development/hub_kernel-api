require "test_helper"
require "rake"
require "json"
require "fileutils"

class DescribeTaskTest < ActiveSupport::TestCase
  setup { Rails.application.load_tasks if Rake::Task.tasks.none? }

  teardown { FileUtils.rm_rf(Rails.root.join("api_descriptions")) }

  test "a host's describe task writes each major's description file into the host's api_descriptions folder" do
    Rake::Task["hub_kernel_api:describe"].execute

    assert_equal({
      "version" => "1.0.0",
      "hubs" => { "shop" => [ { "name" => "price_of", "takes" => [ "item" ], "verb" => "GET" }, { "name" => "restock", "takes" => [ "item" ], "verb" => "POST" }, { "name" => "stock_of", "takes" => [ "item_id" ], "verb" => "GET" } ] }
    }, JSON.parse(File.read(Rails.root.join("api_descriptions", "v1.json"))))
  end
end
