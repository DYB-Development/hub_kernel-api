require "hub_kernel"
require "hub_kernel/api/version"
require "hub_kernel/api/engine"

module HubKernel
  module Api
    class UnservableHubError < StandardError; end

    mattr_accessor :hubs, default: []
    mattr_accessor :base_controller, default: "ActionController::API"
    mattr_accessor :person_method
    mattr_accessor :account_method

    def self.find(name) = addresses[name]

    def self.check!
      problems = unexposed_hubs + shared_addresses
      raise UnservableHubError, problems.join("\n") if problems.any?
    end

    def self.addresses = served.to_h

    def self.served = hubs.flat_map { |entry| entry.is_a?(Hash) ? entry.to_a : [ [ entry.name.demodulize.underscore, entry ] ] }

    def self.unexposed_hubs = served.map(&:last).reject { |hub| hub.respond_to?(:exposures) }.map { |hub| "#{hub.name} exposes no methods to serve" }

    def self.shared_addresses
      served.group_by(&:first).select { |_address, entries| entries.size > 1 }.map do |address, entries|
        "#{entries.map { |_address, hub| hub.name }.join(" and ")} both answer at #{address}"
      end
    end
    private_class_method :served, :unexposed_hubs, :shared_addresses
  end
end
