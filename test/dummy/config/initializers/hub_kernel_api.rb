HubKernel::Api.base_controller = "ApiController"
HubKernel::Api.person_method = :current_person
HubKernel::Api.account_method = :current_account
HubKernel::Api.versions = [ HubKernel::Api::MajorVersion.new(version: "1.0.0"), HubKernel::Api::MajorVersion.new(version: "2.1.0"), HubKernel::Api::MajorVersion.new(version: "3.0.2") ]

Rails.application.config.to_prepare do
  HubKernel::Api.hubs = [ Shop ]
  HubKernel::Authz.check = ->(*) { true }
  HubKernel::Context.scope = ->(_account, &call) { call.call }
  HubKernel::Api.check!
end
