require "hub_kernel-interface"
require "hub_kernel/api/version"
require "hub_kernel/api/engine"

module HubKernel
  module Api
    UnservableHubError = HubKernel::Interface::UnservableHubError

    mattr_accessor :base_controller, default: "ActionController::API"
    mattr_accessor :person_method
    mattr_accessor :account_method

    def self.hubs = HubKernel::Interface.hubs

    def self.hubs=(hubs)
      HubKernel::Interface.hubs = hubs
    end

    def self.find(name) = HubKernel::Interface.find(name)

    def self.check! = HubKernel::Interface.check!
  end
end
