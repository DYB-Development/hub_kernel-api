module HubKernel
  module Api
    class HubsController < HubController
      def show
        render json: listing_of(hub)
      end
    end
  end
end
