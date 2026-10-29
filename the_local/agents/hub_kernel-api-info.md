---
name: hub_kernel-api-info
description: Use to learn what hub_kernel-api offers — serving a hub's exposed methods as a JSON API, the served hubs and their addresses, reads and writes, the listings at a hub's address and at the root address with each method's answer shape, the major versions a host serves, deprecates and retires, the headers telling a caller its major is not the newest or is deprecated, the description file written for each served major, and how sign-in, permission and account scope apply to each call.
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
stops, so callers at that major are told on every answer, and can retire a major it no
longer serves so callers naming it are told it is gone. It can write a JSON description of each served major into the app, so the API
at each major can be read and compared without calling it.

## Interface

This local declares no commands. The surface is split between the other two locals:

- **hub_kernel-api-install** owns adding the gem to a host, the configuration that
  names the base controller, the person and account methods, the served hubs, the
  majors served, which of them are deprecated and when each stops, and which are
  retired, the startup check that rejects a hub that cannot be served, the
  errors a host can meet, and mounting the engine.
- **hub_kernel-api-develop** owns the HTTP endpoints a client calls: the listing at
  the root address, the listing at a hub's address, and the call to one exposed
  method, with their verbs, request values, the headers that name and report a
  version, the headers that report a newer major and a deprecated one, the answer shapes the listings give, responses and error statuses, and the
  task that writes each served major's description file and where those files go.

## How to use it

- To put the API into a Rails app, to serve another hub from one that has it, to
  list the majors a host serves, to deprecate one, or to retire one, use the install
  local.
- To write a client against the API, to discover what it may call and the shape of
  each answer, to call it at a particular major, to notice that its major is
  deprecated or has a newer one, to work out why a call answered
  as it did, or to write and read the description files, use the develop local.

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
- **Deprecated major** — a major the host still serves but plans to stop serving,
  optionally with the date it stops. Every answer at it is given as usual and also
  carries headers saying it is deprecated and, when a date is given, that date. The
  headers never change an answer's body, and a deprecated major can still be the one a
  call that names no major is answered at.
- **Unserved major** — a call or listing naming a major the host does not list is
  answered as not acceptable, with a message naming the majors that are served.
- **Retired major** — a major the host still lists but has marked as no longer served.
  A call or listing naming it is answered as gone, with a message naming the newest
  major, whether or not the hub it names is served. A retired major is never the one
  a call that names no major is answered at.
- **No majors listed** — a host that lists no majors does no versioning: every call
  gets the method's own answer, every listing gives each method's own shape, no
  version is reported, and no description file is written.
- **Description file** — one JSON file per listed major that is not retired, written into the host app on
  request and named after the major. It gives the major's full version and every served
  hub's methods, keyed by address, each with its values, verb and answer shape at that
  major. Unlike a listing, it is written for no caller, so it holds every exposed method
  of every served hub with no permission check or account scope applied. Writing the
  files again with nothing changed writes identical files.
