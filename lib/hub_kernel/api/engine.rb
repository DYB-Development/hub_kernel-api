module HubKernel
  module Api
    class Engine < ::Rails::Engine
      isolate_namespace HubKernel::Api
    end
  end
end
