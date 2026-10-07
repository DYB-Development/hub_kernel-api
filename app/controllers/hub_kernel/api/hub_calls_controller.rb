module HubKernel
  module Api
    class HubCallsController < HubController
      wrap_parameters false

      rescue_from HubKernel::Refused, HubKernel::MissingArgumentError, with: :refused
      rescue_from ActiveRecord::RecordNotFound, with: :missing_record

      def answer
        raise ActionController::RoutingError, "Not found" unless asked_with_the_right_verb?

        HubKernel::Interface::CallReasons.refuse_unlisted_values(hub, params[:name], values: values, person: caller_person, account: caller_account)
        render json: { answer: hub.call_exposed(params[:name], values: values, person: caller_person, account: caller_account) }
      end

      private

      def asked_with_the_right_verb? = hub.exposed(params[:name])&.writes == request.post?

      def values = request.query_parameters.merge(request.request_parameters).deep_symbolize_keys

      def refused(refusal) = render(json: { error: refusal.message }, status: :unprocessable_content)

      def missing_record(missing) = render(json: { error: HubKernel::Interface::CallReasons.missing_record(missing) }, status: :not_found)
    end
  end
end
