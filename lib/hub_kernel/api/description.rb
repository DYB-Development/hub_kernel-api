module HubKernel
  module Api
    module Description
      def self.at(major) = { version: major.version, hubs: HubKernel::Interface.served.transform_values { |hub| hub.exposures.map { |exposure| described(exposure, major) } } }

      def self.described(exposure, major) = { name: exposure.name, takes: exposure.takes, verb: exposure.writes ? "POST" : "GET", answer_shape: answer_shape_at(exposure, major) }.compact

      def self.answer_shape_at(exposure, major) = (exposure.earlier_answers.select { |earlier| earlier.major >= major.major }.min_by(&:major) || exposure).answer_shape

      private_class_method :described, :answer_shape_at
    end
  end
end
