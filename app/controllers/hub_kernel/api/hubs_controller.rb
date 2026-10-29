module HubKernel
  module Api
    class HubsController < HubController
      def show
        render json: hub.exposures_for(person: caller_person, account: caller_account).map { |exposure| listed(exposure) }
      end

      private

      def listed(exposure) = { name: exposure.name, takes: exposure.takes, verb: exposure.writes ? "POST" : "GET", answer_shape: answer_shape_at_major(exposure) }.compact

      def answer_shape_at_major(exposure) = (nearest_earlier_answer(exposure) || exposure).answer_shape

      def nearest_earlier_answer(exposure) = exposure.earlier_answers.select { |earlier| earlier.major >= major.major }.min_by(&:major)
    end
  end
end
