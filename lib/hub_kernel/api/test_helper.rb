module HubKernel
  module Api
    module TestHelper
      def assert_answer_shape(hub, name, answer, major:)
        require_json_schemer

        exposure = hub.exposed(name)
        listed = HubKernel::Api.versions.find { |version| version.major == major } || flunk("The host lists no major #{major} to check #{name} at")
        declared = HubKernel::Api::Description.described(exposure, listed)[:answer_shape] || flunk("#{name} declares no answer shape at major #{major}")
        shape = JSONSchemer.schema(declared)
        differences = shape.validate(HubKernel::Api::EarlierAnswers.translate(answer, exposure, listed)).map { |difference| difference["error"] }
        assert differences.empty?, [ "The answer to #{name} at major #{major} does not match its shape", *differences ].join("\n")
      end

      private

      def require_json_schemer
        require "json_schemer"
      rescue LoadError
        raise LoadError, 'assert_answer_shape needs the json_schemer gem, add gem "json_schemer" to the test group of your Gemfile'
      end
    end
  end
end
