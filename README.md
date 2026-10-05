# hub_kernel-api

Serves a hub_kernel hub's exposed methods as a JSON API. The host lists the hubs it
serves, and every call goes through the host's own sign-in, then hub_kernel's permission
check and account scope.

## Usage

Add the gem, then in an initializer name the controller the API inherits from, the two
methods on it that give the person and the account a call is made for, and the hubs it
serves:

```ruby
HubKernel::Api.base_controller = "Api::HubBaseController"
HubKernel::Api.person_method = :current_person
HubKernel::Api.account_method = :current_account

Rails.application.config.to_prepare do
  HubKernel::Api.hubs = [ Supplies ]
end
```

The base controller's own sign-in runs before every call. hub_kernel's permission check
and account scope must also be set, as hub_kernel's readme describes. Mount the engine:

```ruby
mount HubKernel::Api::Engine => "/api/v1/hubs"
```

Each exposed method answers at `/<hub>/<method>`, where `<hub>` is the hub's module name
underscored. A read answers GET and a write answers POST, and the answer is the method's
return value under `answer`.

| Case | Status | Body |
| --- | --- | --- |
| The method answers | 200 | `{"answer": ...}` |
| The hub is not served, the method is not exposed, the verb is wrong, or the host's permission check refuses | 404 | `{"error": "Not found"}` |
| The hub refuses, or a required value is missing | 422 | `{"error": "<reason>"}` |
| A record the call names does not exist | 404 | `{"error": "No <record> has the id <id>"}` |

## Installation

```ruby
gem "hub_kernel-api"
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
