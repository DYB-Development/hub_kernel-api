module HubKernel
  module Api
    class HubCallsController < HubKernel::Api.base_controller.constantize
      def answer
        render json: { answer: hub.call_exposed(params[:name], values: values, person: send(HubKernel::Api.person_method), account: send(HubKernel::Api.account_method)) }
      end

      private

      def hub = HubKernel::Api.find(params[:hub])

      def values = request.query_parameters.merge(request.request_parameters).deep_symbolize_keys
    end
  end
end
