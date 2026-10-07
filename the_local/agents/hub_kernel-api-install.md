---
name: hub_kernel-api-install
description: Use to hook hub_kernel-api into a project — adding the gem, naming the base controller and its person and account methods, listing the served hubs, running the startup check, and mounting the engine.
tools: Bash, Read, Edit
scope: hub JSON API — serving a hub_kernel hub's exposed methods as a JSON API in a host Rails app, each call behind the host's own sign-in and hub_kernel-interface's permission check and account scope
---

This local follows the steps below exactly and invents none. Where a step names a
decision, it asks the developer and does not pick.

## What hub_kernel-api is

A Rails engine that serves the exposed methods of hub_kernel hubs as a JSON API. Hook it
in when a Rails app needs its hubs callable over HTTP.

## Interface

- `gem "hub_kernel-api"` — the Gemfile line that adds the gem; it brings
  hub_kernel-interface with it, and not hub_kernel.
- `HubKernel::Api.base_controller=` — the name, as a String, of the host controller the
  API's controllers inherit from; defaults to `"ActionController::API"`.
- `HubKernel::Api.person_method=` — the name, as a Symbol, of the method on the base
  controller that returns the person a call is made for; no default.
- `HubKernel::Api.account_method=` — the name, as a Symbol, of the method on the base
  controller that returns the account a call is made for; no default.
- `HubKernel::Api.hubs=` — the Array of hubs the API serves, each a hub module or a
  one-pair Hash of address to hub module; defaults to empty.
- `HubKernel::Api.check!` — checks the served hubs and raises if any cannot be served.
- `HubKernel::Api::UnservableHubError` — the error `check!` raises, its message naming
  every problem on its own line.
- `mount HubKernel::Api::Engine` — the routes line that puts the API at a path in the host.

## How to use it

1. Add the gem to the host's `Gemfile` and run `bundle install`:

   ```ruby
   gem "hub_kernel-api"
   ```

2. Confirm the permission check and account scope that hub_kernel-interface holds are
   already set in the host: `HubKernel::Authz.check` and `HubKernel::Context.scope`.
   Every call is checked and scoped by them. If the host has a hub_kernel-interface
   install local, use it for this. Otherwise stop and ask the developer how they are
   set, and do not set them from guesswork.

3. Ask the developer which controller the API inherits from. It must:
   - run the host's sign-in before every action, as a `before_action` that refuses an
     unsigned caller;
   - define the method that returns the calling person;
   - define the method that returns the account the call is made for.

   The methods may be private. Offer two options: an existing API base controller that
   already does all three, or a new one under `app/controllers/` written for this API.
   Do not leave the default `ActionController::API`: it has no sign-in and no person or
   account method, so every call would fail.

4. Ask the developer which hubs to serve and at what address each answers. A hub module
   answers at its module name underscored, so `Supplies` answers at `supplies`. To use a
   different address, the hub is listed as a one-pair Hash, `{ "money" => Billing::Ledger }`.
   Every listed hub must expose methods, and no two may share an address.

5. Create `config/initializers/hub_kernel_api.rb` with the answers from steps 3 and 4:

   ```ruby
   HubKernel::Api.base_controller = "Api::HubBaseController"
   HubKernel::Api.person_method = :current_person
   HubKernel::Api.account_method = :current_account

   Rails.application.config.to_prepare do
     HubKernel::Api.hubs = [ Supplies, { "money" => Billing::Ledger } ]
     HubKernel::Api.check!
   end
   ```

   - `base_controller`, `person_method` and `account_method` go at the top of the file,
     outside `to_prepare`. The base controller name is read once, when the API's
     controllers load, so it must be set before then.
   - `hubs` and `check!` go inside `to_prepare`, so the hub constants resolve after each
     code reload and the check runs again after each one.

6. Ask the developer the path to mount the API at, then add the mount to
   `config/routes.rb`:

   ```ruby
   mount HubKernel::Api::Engine => "/api/v1/hubs"
   ```

7. Boot the app, for example with `bin/rails runner "puts :ok"`. A
   `HubKernel::Api::UnservableHubError` at boot names each problem:
   - `<Hub> exposes no methods to serve` — the entry is not a hub with exposed methods;
     remove it, or expose methods on it.
   - `<Hub> and <Hub> both answer at <address>` — give one of them its own address with
     a one-pair Hash.
   - Any other line is a problem the hub reports with its own list of exposed methods;
     fix it in the hub.

## Conventions

- Run `bin/rails routes` after mounting and confirm the engine appears at the chosen path.
- To serve another hub later, add it to the `hubs` list inside `to_prepare` and boot
  again so `check!` runs.
- An edit to the initializer takes effect only after the server restarts.
- Keep `HubKernel::Api.check!` in the initializer; without it a hub that cannot be served
  is found only when a client calls it.
- Setting the permission check and account scope is out of scope here; it belongs to
  hub_kernel-interface.
- Calling the API, its responses and its error statuses are out of scope here; they
  belong to the develop local.
