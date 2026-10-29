require "active_support/core_ext/array/conversions"

module HubKernel
  module Api
    class HubController < HubKernel::Api.base_controller.constantize
      rescue_from ActionController::RoutingError, HubKernel::NotAllowed, with: :not_found
      rescue_from HubKernel::Api::UnservedMajorError, with: :unserved_major

      before_action :report_major, if: -> { HubKernel::Api.versions.any? }

      private

      def hub = @hub ||= HubKernel::Api.find(params[:hub]) || raise(ActionController::RoutingError, "Not found")

      def major = @major ||= named_version ? named_major : HubKernel::Api.versions.min_by(&:major)

      def named_version = request.headers["Accept-Version"]

      def named_major = HubKernel::Api.versions.find { |listed| listed.major.to_s == named_version } || raise(HubKernel::Api::UnservedMajorError, "Major #{named_version} is not served, the majors served are #{served_majors}")

      def served_majors = HubKernel::Api.versions.map(&:major).to_sentence(last_word_connector: " and ")

      def report_major
        response.headers["Vary"] = "Accept-Version"
        response.headers["Api-Version"] = major.version
      end

      def listing_of(hub) = hub.exposures_for(person: caller_person, account: caller_account).map { |exposure| listed(exposure) }

      def listed(exposure) = { name: exposure.name, takes: exposure.takes, verb: exposure.writes ? "POST" : "GET", answer_shape: answer_shape_at_major(exposure) }.compact

      def answer_shape_at_major(exposure)
        return exposure.answer_shape if HubKernel::Api.versions.empty?

        (nearest_earlier_answer(exposure) || exposure).answer_shape
      end

      def nearest_earlier_answer(exposure) = exposure.earlier_answers.select { |earlier| earlier.major >= major.major }.min_by(&:major)

      def caller_person = send(HubKernel::Api.person_method || HubKernel::Interface.person_method)

      def caller_account = send(HubKernel::Api.account_method || HubKernel::Interface.account_method)

      def not_found = render(json: { error: "Not found" }, status: :not_found)

      def unserved_major(refusal) = render(json: { error: refusal.message }, status: :not_acceptable)
    end
  end
end
