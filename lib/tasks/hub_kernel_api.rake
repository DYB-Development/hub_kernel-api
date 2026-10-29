require "fileutils"

namespace :hub_kernel_api do
  desc "Write one JSON description file for each listed major that is not retired into the api_descriptions folder"
  task describe: :environment do
    FileUtils.mkdir_p(Rails.root.join("api_descriptions"))
    HubKernel::Api::DescriptionFiles.write(Rails.root.join("api_descriptions"))
  end
end
