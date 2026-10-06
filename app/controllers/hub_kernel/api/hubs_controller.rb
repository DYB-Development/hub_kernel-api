module HubKernel
  module Api
    class HubsController < HubController
      def show
        render json: hub.exposures_for(person: caller_person, account: caller_account).map { |exposure| listed(exposure) }
      end

      private

      def listed(exposure) = { name: exposure.name, takes: exposure.takes, verb: exposure.writes ? "POST" : "GET" }
    end
  end
end
