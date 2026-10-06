HubKernel::Api.base_controller = "ApiController"
HubKernel::Api.person_method = :current_person
HubKernel::Api.account_method = :current_account

Rails.application.config.to_prepare do
  HubKernel::Api.hubs = [ Shop ]
  HubKernel::Authz.check = ->(*) { true }
  HubKernel::Context.scope = ->(_account, &call) { call.call }
  HubKernel::Api.check!
end
