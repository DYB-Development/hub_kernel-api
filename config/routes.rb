HubKernel::Api::Engine.routes.draw do
  match ":hub/:name", to: "hub_calls#answer", via: [ :get, :post ]
end
