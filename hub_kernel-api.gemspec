require_relative "lib/hub_kernel/api/version"

Gem::Specification.new do |spec|
  spec.name        = "hub_kernel-api"
  spec.version     = HubKernel::Api::VERSION
  spec.authors     = [ "tylercschneider" ]
  spec.email       = [ "tylercschneider@gmail.com" ]
  spec.homepage    = "https://github.com/DYB-Development/hub_kernel-api"
  spec.summary     = "Serves a hub_kernel hub's exposed methods as a JSON API."
  spec.description = "hub_kernel-api gives any hub built on hub_kernel a JSON API: the host lists the hubs it serves, and every call goes through the host's sign-in, permission check and account scope."
  spec.license     = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 8.1.3"
  spec.add_dependency "hub_kernel", "~> 0.11"
end
