module HubKernel
  module Api
    class HubCallsController < HubKernel::Api.base_controller.constantize
      rescue_from(ActionController::RoutingError, HubKernel::NotAllowed) { render json: { error: "Not found" }, status: :not_found }
      rescue_from(HubKernel::Refused) { |refusal| render json: { error: refusal.message }, status: :unprocessable_content }

      def answer
        raise ActionController::RoutingError, "Not found" unless hub.exposed(params[:name])&.writes == request.post?

        render json: { answer: hub.call_exposed(params[:name], values: values, person: send(HubKernel::Api.person_method), account: send(HubKernel::Api.account_method)) }
      end

      private

      def hub = HubKernel::Api.find(params[:hub]) || raise(ActionController::RoutingError, "Not found")

      def values = request.query_parameters.merge(request.request_parameters).deep_symbolize_keys
    end
  end
end
