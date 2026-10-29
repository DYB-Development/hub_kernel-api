module HubKernel
  module Api
    module TestHelper
      def assert_answer_shape(hub, name, answer, major:)
        require "json_schemer"

        listed = HubKernel::Api.versions.find { |version| version.major == major }
        assert JSONSchemer.schema(HubKernel::Api::Description.described(hub.exposed(name), listed)[:answer_shape]).valid?(answer)
      end
    end
  end
end
