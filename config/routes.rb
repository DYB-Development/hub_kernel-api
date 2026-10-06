HubKernel::Api::Engine.routes.draw do
  get ":hub", to: "hubs#show"
  match ":hub/:name", to: "hub_calls#answer", via: [ :get, :post ]
end
