require "fileutils"

namespace :hub_kernel_api do
  desc "Write one JSON description file for each listed major that is not retired into the api_descriptions folder"
  task describe: :environment do
    FileUtils.mkdir_p(Rails.root.join("api_descriptions"))
    HubKernel::Api::DescriptionFiles.write(Rails.root.join("api_descriptions"))
  end

  desc "Fail when a listed major that is not retired removes or renames something its committed file in the api_descriptions folder holds"
  task check_descriptions: :environment do
    HubKernel::Api::DescriptionCheck.check!(Rails.root.join("api_descriptions"))
  end
end
