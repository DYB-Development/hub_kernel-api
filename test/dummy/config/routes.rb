Rails.application.routes.draw do
  mount HubKernel::Api::Engine => "/hub_kernel-api"
end
