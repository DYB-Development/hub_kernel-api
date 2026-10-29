---
name: hub_kernel-api-install
description: Use to hook hub_kernel-api into a project — adding the gem, naming the base controller and its person and account methods, listing the served hubs, listing the majors served and marking the ones deprecated or retired, running the startup check, and mounting the engine.
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
  controller that returns the person a call is made for; when unset, the API uses
  `HubKernel::Interface.person_method`.
- `HubKernel::Api.account_method=` — the name, as a Symbol, of the method on the base
  controller that returns the account a call is made for; when unset, the API uses
  `HubKernel::Interface.account_method`.
- `HubKernel::Api.hubs=` — the Array of hubs the API serves, each a hub module or a
  one-pair Hash of address to hub module; defaults to empty.
- `HubKernel::Api.versions=` — the Array of majors the API serves, each a
  `HubKernel::Api::MajorVersion`; defaults to empty, which turns versioning off.
- `HubKernel::Api::MajorVersion` — one listed major, built as
  `HubKernel::Api::MajorVersion.new(version: "1.4.0")`; its major is the first part of
  the version. `deprecated: true` marks a major the host still serves but plans to stop
  serving, `deprecated_on:` gives a deprecated major the `Date` it was deprecated, and
  `sunset:` gives it the `Date` it stops being served. `retired: true` marks a major the
  host keeps listed but no longer serves.
- `HubKernel::Api.check!` — checks the served hubs and the listed majors, and raises if
  any hub cannot be served or the majors hold a mistake.
- `HubKernel::Api::UnservableHubError` — the error `check!` raises, its message naming
  every problem on its own line.
- `HubKernel::Api::UnservedMajorError` — the error the API raises when a call names a
  major the host does not list; the API answers that call with status 406 and the
  error's message, and the host does not rescue it.
- `HubKernel::Api::RetiredMajorError` — the error the API raises when a call or a listing
  names a retired major, whether or not the hub it names is served; the API answers that
  call with status 410 and the error's message, and the host does not rescue it.
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

4. Check whether the host already sets `HubKernel::Interface.person_method` and
   `HubKernel::Interface.account_method`, for example for hub_kernel-mcp. If it does and
   the base controller defines those same methods, ask the developer whether to rely on
   them or to set `HubKernel::Api.person_method` and `HubKernel::Api.account_method`. If
   it does not, set both on `HubKernel::Api`.

5. Ask the developer which hubs to serve and at what address each answers. A hub module
   answers at its module name underscored, so `Supplies` answers at `supplies`. To use a
   different address, the hub is listed as a one-pair Hash, `{ "money" => Billing::Ledger }`.
   Every listed hub must expose methods, and no two may share an address. The served list
   is the one hub_kernel-interface holds, so another interface gem in the host, such as
   hub_kernel-mcp, serves the same list; set it once, through either gem.

6. Ask the developer whether the API serves major versions, and if it does, the full
   version of each major, in major.minor.patch form. Put these facts to them:
   - With no majors listed, every call gets the method's own answer, a call that names a
     major is answered as though it named none, and the API reports no version.
   - With majors listed, a call or listing that names no major is answered at the oldest
     major listed that is not retired, so listing majors on a host with existing clients
     changes the answers and the answer shapes those clients receive unless that major is
     the one they were built against.
   - A major marked `retired: true` stays listed, and every call or listing that names it
     is answered with status 410.
   - A major marked `deprecated: true` is still answered, and every answer at it gives the
     caller its `deprecated_on:` date and its `sunset:` date.
   - `deprecated_on:` and `sunset:` on a major not marked `deprecated: true` are never sent
     to a caller.
   - `HubKernel::Api.check!` refuses to boot the host when the list holds any of these:
     a version not a string in major.minor.patch form, a major listed twice, a deprecated major
     missing `deprecated_on:` or `sunset:`, a `deprecated_on:` or `sunset:` that is not a
     `Date`, or every listed major retired.
   - It also refuses when a served hub declares an earlier answer for a major the host
     does not list, or for the newest major listed. Ask the developer which majors their
     hubs already declare earlier answers for, and list each of those majors.

   Ask which majors, if any, are deprecated, and for each one the date it was deprecated
   and the date it stops being served; both dates are required. Ask which majors, if any,
   are retired, and keep at least one not retired. Do not mark a major deprecated or
   retired without the developer's word: deprecating one tells every client built against
   it to move, and retiring one stops every such client getting answers.

7. Create `config/initializers/hub_kernel_api.rb` with the answers from steps 3 to 6:

   ```ruby
   HubKernel::Api.base_controller = "Api::HubBaseController"
   HubKernel::Api.person_method = :current_person
   HubKernel::Api.account_method = :current_account
   HubKernel::Api.versions = [
     HubKernel::Api::MajorVersion.new(version: "1.4.0", retired: true),
     HubKernel::Api::MajorVersion.new(version: "2.0.1", deprecated: true, deprecated_on: Date.new(2026, 9, 30), sunset: Date.new(2027, 3, 31)),
     HubKernel::Api::MajorVersion.new(version: "3.1.0")
   ]

   Rails.application.config.to_prepare do
     HubKernel::Api.hubs = [ Supplies, { "money" => Billing::Ledger } ]
     HubKernel::Api.check!
   end
   ```

   - `base_controller`, `person_method`, `account_method` and `versions` go at the top of
     the file, outside `to_prepare`. The base controller name is read once, when the
     API's controllers load, so it must be set before then.
   - Leave out the `versions` line when the developer chose to serve no majors.
   - Add `deprecated: true` only to the majors the developer named as deprecated.
   - Add `deprecated_on:` and `sunset:` to each of them, as `Date` values, with the dates
     the developer gave.
   - Add `retired: true` only to the majors the developer named as retired.
   - `hubs` and `check!` go inside `to_prepare`, so the hub constants resolve after each
     code reload and the check runs again after each one.

8. Ask the developer the path to mount the API at, then add the mount to
   `config/routes.rb`:

   ```ruby
   mount HubKernel::Api::Engine => "/api/v1/hubs"
   ```

9. Boot the app, for example with `bin/rails runner "puts :ok"`. A
   `HubKernel::Api::UnservableHubError` at boot names each problem:
   - `<Hub> exposes no methods to serve` — the entry is not a hub with exposed methods;
     remove it, or expose methods on it.
   - `<Hub> and <Hub> both answer at <address>` — give one of them its own address with
     a one-pair Hash.
   - `The listed version <version> is not in major.minor.patch form` — write that
     entry's `version:` as a string such as `"2.1.0"`.
   - `Major <n> is listed more than once` — keep one entry for that major.
   - `Major <n> is deprecated with no deprecated_on: date it was deprecated` or
     `... with no sunset: date it stops being served` — ask the developer for the missing
     date and add it.
   - `Major <n> gives deprecated_on: as <value>, which is not a Date` or the same for
     `sunset:` — write the date as `Date.new(year, month, day)`.
   - `Every listed major is retired, ...` — ask the developer which major to stop
     retiring, or which new major to list.
   - `<Hub> declares an earlier answer to <method> for major <n>, which the host does not
     list` — ask the developer whether to list that major or have the hub's earlier answer
     removed.
   - `<Hub> declares an earlier answer to <method> for major <n>, the newest major, ...` —
     ask the developer whether to list a newer major or have that earlier answer removed.
   - Any other line is a problem the hub reports with its own list of exposed methods;
     fix it in the hub.

   Every problem is named in the one error, so fix them all before booting again.

## Conventions

- Run `bin/rails routes` after mounting and confirm the engine appears at the chosen path.
- To serve another hub later, add it to the `hubs` list inside `to_prepare` and boot
  again so `check!` runs.
- To serve a new major, add a `HubKernel::Api::MajorVersion` to `versions`.
- To warn clients that a major will stop being served, add `deprecated: true`,
  `deprecated_on:` with the date it was deprecated, and `sunset:` with the date it stops
  being served. Retire it on that date; nothing retires it when the date passes.
- To stop serving a major, ask the developer whether to retire it or remove it. Adding
  `retired: true` keeps it listed, and every call that names it answers with status 410
  and a message naming the newest major. Removing it while others stay listed makes every
  call that names it answer with status 406, the same as a major never listed.
- Retiring or removing the oldest major that is not retired moves every call that names
  no major to the next oldest one.
- Removing every major turns versioning off, and calls that name a major get the
  method's own answer.
- Removing a major that a served hub declares an earlier answer for, or removing the
  newest major while a hub declares an earlier answer for the one below it, stops the host
  booting; boot again after every change to `versions` so `check!` runs.
- With no majors listed, `check!` checks none of the version rules.
- An edit to the initializer takes effect only after the server restarts.
- Keep `HubKernel::Api.check!` in the initializer; without it a hub that cannot be served,
  or a mistake in `versions`, is found only when a client calls the API.
- Setting the permission check and account scope is out of scope here; it belongs to
  hub_kernel-interface.
- Declaring a method's answers at earlier majors is out of scope here; it belongs to
  hub_kernel-interface.
- Calling the API, naming a major on a call, its responses, its error statuses and
  writing each major's description file are out of scope here; they belong to the
  develop local.
