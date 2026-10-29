require "json"

module HubKernel
  module Api
    module DescriptionFiles
      def self.write(directory)
        removals = DescriptionCheck.removals(directory)
        raise BreakingChangeError, removals.join("\n") if removals.any?

        HubKernel::Api.versions.reject(&:retired?).each { |major| File.write(File.join(directory, "v#{major.major}.json"), JSON.pretty_generate(Description.at(major))) }
      end
    end
  end
end
