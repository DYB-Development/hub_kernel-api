module HubKernel
  module Api
    module TestHelper
      def assert_answer_shape(hub, name, answer, major:)
        require "json_schemer"

        exposure = hub.exposed(name)
        listed = HubKernel::Api.versions.find { |version| version.major == major }
        assert JSONSchemer.schema(HubKernel::Api::Description.described(exposure, listed)[:answer_shape]).valid?(HubKernel::Api::EarlierAnswers.translate(answer, exposure, listed)), "The answer to #{name} at major #{major} does not match its shape"
      end
    end
  end
end
