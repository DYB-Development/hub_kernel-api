module HubKernel
  module Api
    module EarlierAnswers
      def self.translate(answer, exposure, major) = down_to(exposure, major).reduce(answer) { |translated, earlier| earlier.translate(translated) }

      def self.down_to(exposure, major) = exposure.earlier_answers.select { |earlier| earlier.major >= major.major }.sort_by(&:major).reverse

      private_class_method :down_to
    end
  end
end
