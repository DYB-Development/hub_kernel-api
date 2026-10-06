module HubKernel
  module Api
    class HubCallsController < HubController
      wrap_parameters false

      rescue_from HubKernel::Refused, HubKernel::MissingArgumentError, with: :refused
      rescue_from ActiveRecord::RecordNotFound, with: :missing_record

      def answer
        raise ActionController::RoutingError, "Not found" unless asked_with_the_right_verb?
        return refuse_unlisted_values if unlisted_values.any?

        render json: { answer: hub.call_exposed(params[:name], values: values, person: caller_person, account: caller_account) }
      end

      private

      def asked_with_the_right_verb? = hub.exposed(params[:name])&.writes == request.post?

      def refuse_unlisted_values
        raise HubKernel::NotAllowed unless permitted?

        refused(HubKernel::Refused.new("#{params[:name]} does not take #{unlisted_values.join(", ")}"))
      end

      def permitted? = hub.exposures_for(person: caller_person, account: caller_account).any? { |exposure| exposure.name.to_s == params[:name] }

      def unlisted_values = values.keys - hub.exposed(params[:name]).takes

      def values = request.query_parameters.merge(request.request_parameters).deep_symbolize_keys

      def refused(refusal) = render(json: { error: refusal.message }, status: :unprocessable_content)

      def missing_record(missing)
        render json: { error: "No #{missing.model.demodulize.underscore.humanize(capitalize: false)} has the id #{missing.id}" }, status: :not_found
      end
    end
  end
end
