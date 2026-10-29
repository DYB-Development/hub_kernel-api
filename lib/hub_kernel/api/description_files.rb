module HubKernel
  module Api
    module DescriptionFiles
      def self.write(directory)
        HubKernel::Api.versions.each { |major| File.write(File.join(directory, "v#{major.major}.json"), "") }
      end
    end
  end
end
