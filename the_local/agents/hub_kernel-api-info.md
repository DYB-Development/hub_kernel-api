---
name: hub_kernel-api-info
description: Use to learn what hub_kernel-api offers — serving a hub's exposed methods as a JSON API, the served hubs and their addresses, reads and writes, the listings at a hub's address and at the root address with each method's answer shape, the major versions a host serves, deprecates with the date it was deprecated and the date it stops, and retires, the headers telling a caller its major is not the newest or is deprecated, the description file written for each served major, the check that fails when a major removes something its file holds or adds something without raising its minor, the test assertion that checks an answer against its shape, and how sign-in, permission and account scope apply to each call.
tools: Read
scope: hub JSON API — serving a hub_kernel hub's exposed methods as a JSON API in a host Rails app, each call behind the host's own sign-in and hub_kernel-interface's permission check and account scope
---

This local explains hub_kernel-api and makes no changes.

## What hub_kernel-api is

hub_kernel-api is a Rails engine that serves the exposed methods of hub_kernel hubs
as a JSON API inside a host Rails app. The host lists which hubs it serves, and the
gem answers HTTP calls to their exposed methods, a listing of one hub's methods, and a
listing of every served hub's methods at the API's root address. It adds no business
logic of its own: every answer is the return value of a method the hub already exposes.

It depends on hub_kernel-interface alone, not on hub_kernel. hub_kernel-interface
holds the permission check and the account scope, and the host sets both.

Reach for it when a hub's exposed methods need to be called over HTTP, by a mobile
app, another service or a front end, without writing a controller per method. Each
call runs the host's own sign-in first, then hub_kernel-interface's permission check
and account scope, so the API never shows a caller more than the app itself would.
A client can learn from the listings what it may call and what shape each answer
takes. A host can also serve several major versions of the API at the same addresses,
so an older client keeps getting the answers it was built for after a method's answer
changes. It can mark a major it plans to stop serving as deprecated, with the date it
was deprecated and the date it stops, so callers at that major are told on every
answer, and can retire a major it no longer serves so callers naming it are told it is
gone. It can write a JSON description of each served major into the app, so the API at
each major can be read and compared without calling it, and its CI can fail a change that
breaks a major's file. A host's tests can check that a
method's answer still matches the shape it declares at a major, since a call never checks
that itself.

## Interface

This local declares no commands. The surface is split between the other two locals:

- **hub_kernel-api-install** owns adding the gem to a host, the configuration that
  names the base controller, the person and account methods, the served hubs, the
  majors served, which of them are deprecated, when each was deprecated and when each
  stops, and which are retired, the startup check that rejects a hub that cannot be served
  or a list of majors with a mistake in it, the errors a host can meet, and mounting the
  engine.
- **hub_kernel-api-develop** owns the HTTP endpoints a client calls: the listing at
  the root address, the listing at a hub's address, and the call to one exposed
  method, with their verbs, request values, the headers that name and report a
  version, the headers that report a newer major and a deprecated one, the answer
  shapes the listings give, responses and error statuses, the task that writes each
  served major's description file and where those files go, the check that compares
  each major with its file and the error it raises, and the test assertion
  that checks an answer against its shape.

## How to use it

- To put the API into a Rails app, to serve another hub from one that has it, to
  list the majors a host serves, to deprecate one, or to retire one, use the install
  local.
- To write a client against the API, to discover what it may call and the shape of
  each answer, to call it at a particular major, to notice that its major is
  deprecated or has a newer one, to work out why a call answered
  as it did, to write and read the description files, to have CI fail a breaking
  change to a major, or to test that a method's
  answer matches its shape, use the develop local.

## Conventions

- **Hub** — a module whose methods are declared as exposed through
  hub_kernel-interface. Only exposed methods are reachable; nothing else on the hub is.
- **Served hub** — a hub the host has listed for the API. A hub that is not served is
  answered as not found, as if it did not exist.
- **Address** — the name a served hub answers at. By default it is the hub's module
  name underscored, so `Supplies` answers at `supplies`. The host may give a hub a
  different address, and the permission check still asks about the hub by its own
  name, such as `ledger:record_spend`.
- **Read and write** — each exposed method is one or the other. A read answers GET
  and a write answers POST, and the wrong verb is answered as not found.
- **Takes** — the values an exposed method is listed with. A permitted call that
  sends a value outside that list is refused.
- **Person and account** — who is calling and which account the call is made for,
  both supplied by the host's base controller after its own sign-in. Every call and
  every listing is scoped to them.
- **Hub listing** — the methods of one served hub the caller may call, each with its
  name, the values it takes, its verb and its answer shape.
- **Root address listing** — every served hub's listing keyed by the hub's address,
  given at the API's root address, together with the full version of the major it
  describes.
- **Answer** — a successful call returns the method's return value under the
  `answer` key.
- **Answer shape** — the JSON Schema a method declares for its answer, through
  hub_kernel-interface. A listing gives each method's shape at the major the caller
  named, and a method with no declared shape at that major is listed with no shape.
- **Not found and refused** — a call the permission check denies is answered as not
  found, so a caller cannot tell a forbidden method from a missing one. A call the hub
  itself refuses, or one missing a required value, is answered as unprocessable with
  the reason.
- **Major and full version** — the host lists each major it serves by a full version
  in major.minor.patch form, and the major is that version's first part. Every
  method answers at the same address at every major, and a call or listing that names
  no major is answered at the oldest one listed that is not retired.
- **Earlier answer** — a hub method always answers in the newest major's shape. A
  method whose answer changed declares, through hub_kernel-interface, how to turn its
  answer back into an older major's shape, and may declare that older shape too. A
  call at an older major gets the answer passed through each of those from the newest
  down to the major named.
- **Newest major** — the listed major with the highest number. Every answer at an
  older major carries a header giving the newest major's full version, so a caller
  learns a newer major exists without asking.
- **Deprecated major** — a major the host still serves but plans to stop serving, given
  the date it was deprecated and the date it stops, both as dates. Every answer at it is
  given as usual, and carries a header giving each of those dates. The headers never
  change an answer's body, and a deprecated major can still be the one a call that names
  no major is answered at.
- **Unserved major** — a call or listing naming a major the host does not list is
  answered as not acceptable, with a message naming the majors that are served.
- **Retired major** — a major the host still lists but has marked as no longer served.
  A call or listing naming it is answered as gone, with a message naming the newest
  major, whether or not the hub it names is served. A retired major is never the one
  a call that names no major is answered at.
- **No majors listed** — a host that lists no majors does no versioning: every call
  gets the method's own answer, every listing gives each method's own shape, no
  version is reported, no description file is written, and the startup check checks
  no majors.
- **Startup check** — run when the host boots, it refuses to let the app start while a
  served hub cannot be served or the listed majors hold a mistake, and names every
  problem it found. A mistake in the majors is a version not a string in major.minor.patch form,
  a major listed twice, a deprecated major missing either date, a date given as
  something other than a date, every major retired, or a hub declaring an earlier answer
  for a major the host does not list or for the newest major.
- **Description file** — one JSON file per listed major that is not retired, written into the host app on
  request and named after the major. It gives the major's full version and every served
  hub's methods, keyed by address, each with its values, verb and answer shape at that
  major. Unlike a listing, it is written for no caller, so it holds every exposed method
  of every served hub with no permission check or account scope applied. Writing the
  files again with nothing changed writes identical files. Writing them is refused, with
  nothing written, while any major removes or renames something its existing file holds,
  or adds something without raising its minor.
- **Breaking change check** — a check a host's CI runs that compares each major that is
  not retired with the description file it already has, and fails naming every problem
  at once. A major breaks its file when its current description no longer holds a hub, a
  method, a value the method takes, its verb, or a key or value in its answer shape that
  the file holds, and a rename counts as the old name removed. An object in a list that
  has no name, such as a choice in an `anyOf`, is matched by its position. It also breaks its file
  when it adds something the file does not hold while the minor of its full version is no
  higher than the minor in the file. A change that keeps every key and value but changes
  what a value means passes, and a retired major or a major with no file is not compared.
- **Shape assertion** — a test assertion a host includes in its own tests. It takes a
  hub, a method's name, the method's own answer and a listed major, turns the answer
  down to that major as a call would, and checks it against the method's shape at that
  major. It fails naming the method, the major and each place the answer differs, and
  also fails when the host lists no such major or the method declares no shape at it.
  It needs a JSON Schema gem in the host's test group, and hub_kernel-api loads that
  gem only when the assertion runs, so a host without it still loads hub_kernel-api.
