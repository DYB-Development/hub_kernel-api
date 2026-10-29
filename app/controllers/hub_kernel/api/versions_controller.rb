module HubKernel
  module Api
    class VersionsController < HubController
      def show
        render json: { version: major.version, hubs: HubKernel::Interface.served.transform_values { |served| listing_of(served) } }
      end
    end
  end
end
