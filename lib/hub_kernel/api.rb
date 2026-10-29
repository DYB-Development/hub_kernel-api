require "hub_kernel-interface"
require "hub_kernel/api/version"
require "hub_kernel/api/major_version"
require "hub_kernel/api/description"
require "hub_kernel/api/description_files"
require "hub_kernel/api/engine"

module HubKernel
  module Api
    UnservableHubError = HubKernel::Interface::UnservableHubError
    class UnservedMajorError < StandardError; end

    mattr_accessor :base_controller, default: "ActionController::API"
    mattr_accessor :person_method
    mattr_accessor :account_method
    mattr_accessor :versions, default: []

    def self.hubs = HubKernel::Interface.hubs

    def self.hubs=(hubs)
      HubKernel::Interface.hubs = hubs
    end

    def self.find(name) = HubKernel::Interface.find(name)

    def self.check! = HubKernel::Interface.check!
  end
end
