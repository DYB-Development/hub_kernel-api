Rails.application.routes.draw do
  mount HubKernel::Api::Engine => "/hubs"
end
