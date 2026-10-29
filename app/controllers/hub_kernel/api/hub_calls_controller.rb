module HubKernel
  module Api
    class HubCallsController < HubController
      wrap_parameters false

      rescue_from HubKernel::Refused, HubKernel::MissingArgumentError, with: :refused
      rescue_from ActiveRecord::RecordNotFound, with: :missing_record

      def answer
        raise ActionController::RoutingError, "Not found" unless asked_with_the_right_verb?

        HubKernel::Interface::CallReasons.refuse_unlisted_values(hub, params[:name], values: values, person: caller_person, account: caller_account)
        render json: { answer: at_major(hub.call_exposed(params[:name], values: values, person: caller_person, account: caller_account)) }
      end

      private

      def asked_with_the_right_verb? = hub.exposed(params[:name])&.writes == request.post?

      def at_major(answer)
        return answer unless major

        earlier_answers_down_to_major.reduce(answer) { |translated, earlier| earlier.translate(translated) }
      end

      def earlier_answers_down_to_major = hub.exposed(params[:name]).earlier_answers.select { |earlier| earlier.major >= major.major }.sort_by(&:major).reverse

      def values = request.query_parameters.merge(request.request_parameters).deep_symbolize_keys

      def refused(refusal) = render(json: { error: refusal.message }, status: :unprocessable_content)

      def missing_record(missing) = render(json: { error: HubKernel::Interface::CallReasons.missing_record(missing) }, status: :not_found)
    end
  end
end
