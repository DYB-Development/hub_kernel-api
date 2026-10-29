module HubKernel
  module Api
    class VersionsController < HubController
      def show
        render json: { version: described_version, hubs: HubKernel::Interface.served.transform_values { |served| listing_of(served) } }.compact
      end

      private

      def described_version
        major.version if HubKernel::Api.versions.any?
      end
    end
  end
end
