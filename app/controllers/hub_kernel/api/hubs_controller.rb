module HubKernel
  module Api
    class HubsController < HubKernel::Api.base_controller.constantize
      def show
        render json: HubKernel::Api.find(params[:hub]).exposures_for(person: send(HubKernel::Api.person_method), account: send(HubKernel::Api.account_method)).map { |exposure| { name: exposure.name, takes: exposure.takes, verb: exposure.writes ? "POST" : "GET" } }
      end
    end
  end
end
