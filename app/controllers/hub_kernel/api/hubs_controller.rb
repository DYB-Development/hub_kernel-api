module HubKernel
  module Api
    class HubsController < HubKernel::Api.base_controller.constantize
      def show
        render json: HubKernel::Api.find(params[:hub]).exposures.map { |exposure| { name: exposure.name, takes: exposure.takes, verb: exposure.writes ? "POST" : "GET" } }
      end
    end
  end
end
