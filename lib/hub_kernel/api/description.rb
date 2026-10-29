module HubKernel
  module Api
    module Description
      def self.at(major) = { version: major.version }
    end
  end
end
