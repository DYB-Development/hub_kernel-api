# hub_kernel-api

Serves a hub_kernel hub's exposed methods as a JSON API. The host lists the hubs it
serves, and every call goes through the host's own sign-in, then the permission check and
account scope that hub_kernel-interface holds. It depends on hub_kernel-interface alone, not
on hub_kernel.

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
  HubKernel::Api.check!
end
```

When `HubKernel::Api.person_method` or `HubKernel::Api.account_method` is not set, the JSON
API uses `HubKernel::Interface.person_method` or `HubKernel::Interface.account_method`, so a
host that also serves hub_kernel-mcp can name the caller once in hub_kernel-interface. The
JSON API's own setting is used when it is set.

`HubKernel::Api.check!` raises `HubKernel::Api::UnservableHubError` when a served entry
exposes no methods, when two served hubs answer at the same address, or when a served
hub's exposed list has a problem, naming each. Inside `to_prepare` it runs again after
every code reload.

`HubKernel::Api.hubs` reads and writes hub_kernel-interface's one served list,
`HubKernel::Interface.hubs`, so every interface gem in the host, such as hub_kernel-mcp,
serves the same hubs at the same names. The list is set once, through either gem.

The base controller's own sign-in runs before every call. The permission check and account
scope must also be set, `HubKernel::Authz.check` and `HubKernel::Context.scope`, as
hub_kernel-interface's readme describes. Mount the engine:

```ruby
mount HubKernel::Api::Engine => "/api/v1/hubs"
```

Each exposed method answers at `/<hub>/<method>`, where `<hub>` is the hub's module name
underscored. To answer at a name of the host's choosing, list the hub as a one-pair hash:

```ruby
HubKernel::Api.hubs = [ Supplies, { "money" => Billing::Ledger } ]
```

A hub listed this way answers only at the name given, and the permission check is still
asked about it by its own name, such as `ledger:record_spend`. A read answers GET and a write answers POST, and the answer is the method's
return value under `answer`.

A GET at a served hub's own address, `/<hub>`, lists the methods the caller may call on
the account the host names, each with its name, the values it takes and its verb:

```json
[{ "name": "price_of", "takes": ["item"], "verb": "GET" }]
```

A hub that is not served is answered as not found, and a caller the host's sign-in refuses
is shown nothing.

| Case | Status | Body |
| --- | --- | --- |
| The method answers | 200 | `{"answer": ...}` |
| The hub is not served, the method is not exposed, the verb is wrong, or the host's permission check refuses | 404 | `{"error": "Not found"}` |
| The hub refuses, or a required value is missing | 422 | `{"error": "<reason>"}` |
| A permitted call sends a value the method is not listed with | 422 | `{"error": "<method> does not take <values>"}` |
| A record the call names does not exist | 404 | `{"error": "No <record> has the id <id>"}` |

## Versions

A host lists the major versions it serves, each by its full version in major.minor.patch
form. The major is the first part of that version:

```ruby
HubKernel::Api.versions = [
  HubKernel::Api::MajorVersion.new(version: "1.4.0"),
  HubKernel::Api::MajorVersion.new(version: "2.0.1")
]
```

A method answers at the same address at every major. A caller names the major it was built
for in an `Accept-Version` request header, such as `Accept-Version: 1`. A call that sends no
`Accept-Version` header is answered at the oldest major listed.

A hub method answers in the newest major's shape. A method whose answer changed in a newer
major declares its earlier answers with `exposes`, as hub_kernel-interface's readme
describes:

```ruby
exposes :shelf_of, takes: %i[item], writes: false, earlier_answers: {
  1 => ->(answer) { answer.transform_keys(aisle: :shelf) }
}
```

A call naming an older major answers with the method's answer passed through each earlier
answer the method declares for the majors from the newest down to the one named, newest
first. A call naming the newest major answers with the method's own answer.

Every answer at a listed major, including a hub listing and a hub's refusal, carries an
`Api-Version` header giving the full version it was answered at. Every answer, including
the refusal below, carries a `Vary: Accept-Version` header.

A call naming a major the host does not list is answered with status 406 and no
`Api-Version` header. The controller raises `HubKernel::Api::UnservedMajorError` and
renders its message:

```json
{ "error": "Major 7 is not served, the majors served are 1 and 2" }
```

A host that lists no majors ignores any `Accept-Version` header, answers every call with
the method's own answer, and sends no version headers.

## Answer shapes

A method can declare the JSON Schema of its answer, and each earlier answer can declare
the shape of the answer at its major, with `exposes` as hub_kernel-interface's readme
describes:

```ruby
exposes :shelf_of, takes: %i[item], writes: false, answer_shape: { "type" => "object", "required" => [ "aisle" ] }, earlier_answers: {
  1 => { translation: ->(answer) { answer.transform_keys(aisle: :shelf) }, answer_shape: { "type" => "object", "required" => [ "shelf" ] } }
}
```

A hub listing, `/<hub>`, gives each method's `answer_shape` at the major the caller names
in `Accept-Version`, or at the oldest major listed when it names none:

```json
[{ "name": "shelf_of", "takes": ["item"], "verb": "GET", "answer_shape": { "type": "object", "required": ["shelf"] } }]
```

A method's shape at the newest major is its own `answer_shape`. Its shape at an older major
is the shape of the earlier answer declared for that major, or else its shape at the major
after it. A method with no declared shape at that major, including one whose earlier answer
for it declares none, is listed with no `answer_shape` key. A host that lists no majors
lists each method's own shape.

A GET at the API's root address, `/`, lists every served hub's methods the caller may call,
keyed by the hub's address, each as a hub listing gives it, together with the full version
of the major it describes:

```json
{ "version": "1.4.0", "hubs": { "supplies": [{ "name": "shelf_of", "takes": ["item"], "verb": "GET", "answer_shape": { "type": "object", "required": ["shelf"] } }] } }
```

A host that lists no majors gives no `version` key. The root address listing refuses a
major the host does not list with status 406, as a call does.

## Installation

```ruby
gem "hub_kernel-api"
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
