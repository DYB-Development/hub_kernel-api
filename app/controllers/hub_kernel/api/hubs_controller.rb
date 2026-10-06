module HubKernel
  module Api
    class HubsController < HubKernel::Api.base_controller.constantize
      rescue_from(ActionController::RoutingError) { render json: { error: "Not found" }, status: :not_found }

      def show
        render json: hub.exposures_for(person: send(HubKernel::Api.person_method), account: send(HubKernel::Api.account_method)).map { |exposure| { name: exposure.name, takes: exposure.takes, verb: exposure.writes ? "POST" : "GET" } }
      end

      private

      def hub = HubKernel::Api.find(params[:hub]) || raise(ActionController::RoutingError, "Not found")
    end
  end
end
