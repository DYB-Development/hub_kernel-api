require "hub_kernel"
require "hub_kernel/api/version"
require "hub_kernel/api/engine"

module HubKernel
  module Api
    mattr_accessor :hubs, default: []
    mattr_accessor :base_controller, default: "ActionController::API"
    mattr_accessor :person_method
    mattr_accessor :account_method

    def self.find(name) = addresses[name]

    def self.addresses = hubs.reduce({}) { |found, entry| found.merge(entry.is_a?(Hash) ? entry : { entry.name.demodulize.underscore => entry }) }
  end
end
