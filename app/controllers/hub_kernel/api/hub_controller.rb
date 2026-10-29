module HubKernel
  module Api
    class HubController < HubKernel::Api.base_controller.constantize
      rescue_from ActionController::RoutingError, HubKernel::NotAllowed, with: :not_found

      before_action :report_major

      private

      def hub = @hub ||= HubKernel::Api.find(params[:hub]) || raise(ActionController::RoutingError, "Not found")

      def major = @major ||= HubKernel::Api.versions.find { |listed| listed.major.to_s == request.headers["Accept-Version"] } || HubKernel::Api.versions.min_by(&:major)

      def report_major
        response.headers["Api-Version"] = major.version
      end

      def caller_person = send(HubKernel::Api.person_method || HubKernel::Interface.person_method)

      def caller_account = send(HubKernel::Api.account_method || HubKernel::Interface.account_method)

      def not_found = render(json: { error: "Not found" }, status: :not_found)
    end
  end
end
