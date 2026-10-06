module HubKernel
  module Api
    class HubController < HubKernel::Api.base_controller.constantize
      rescue_from ActionController::RoutingError, HubKernel::NotAllowed, with: :not_found

      private

      def hub = @hub ||= HubKernel::Api.find(params[:hub]) || raise(ActionController::RoutingError, "Not found")

      def caller_person = send(HubKernel::Api.person_method)

      def caller_account = send(HubKernel::Api.account_method)

      def not_found = render(json: { error: "Not found" }, status: :not_found)
    end
  end
end
