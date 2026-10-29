---
name: hub_kernel-api-info
description: Use to learn what hub_kernel-api offers — serving a hub's exposed methods as a JSON API, the served hubs and their addresses, reads and writes, the major versions a host serves, and how sign-in, permission and account scope apply to each call.
tools: Read
scope: hub JSON API — serving a hub_kernel hub's exposed methods as a JSON API in a host Rails app, each call behind the host's own sign-in and hub_kernel-interface's permission check and account scope
---

This local explains hub_kernel-api and makes no changes.

## What hub_kernel-api is

hub_kernel-api is a Rails engine that serves the exposed methods of hub_kernel hubs
as a JSON API inside a host Rails app. The host lists which hubs it serves, and the
gem answers HTTP calls to their exposed methods and to a listing of them. It adds no
business logic of its own: every answer is the return value of a method the hub
already exposes.

It depends on hub_kernel-interface alone, not on hub_kernel. hub_kernel-interface
holds the permission check and the account scope, and the host sets both.

Reach for it when a hub's exposed methods need to be called over HTTP, by a mobile
app, another service or a front end, without writing a controller per method. Each
call runs the host's own sign-in first, then hub_kernel-interface's permission check
and account scope, so the API never shows a caller more than the app itself would.
A host can also serve several major versions of the API at the same addresses, so an
older client keeps getting the answers it was built for after a method's answer changes.

## Interface

This local declares no commands. The surface is split between the other two locals:

- **hub_kernel-api-install** owns adding the gem to a host, the configuration that
  names the base controller, the person and account methods, the served hubs and the
  majors served, the startup check that rejects a hub that cannot be served, the
  errors a host can meet, and mounting the engine.
- **hub_kernel-api-develop** owns the HTTP endpoints a client calls: the listing at a
  hub's address and the call to one exposed method, with their verbs, request values,
  the headers that name and report a version, responses and error statuses.

## How to use it

- To put the API into a Rails app, to serve another hub from one that has it, or to
  list the majors a host serves, use the install local.
- To write a client against the API, to call it at a particular major, or to work
  out why a call answered as it did, use the develop local.

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
- **Answer** — a successful call returns the method's return value under the
  `answer` key.
- **Not found and refused** — a call the permission check denies is answered as not
  found, so a caller cannot tell a forbidden method from a missing one. A call the hub
  itself refuses, or one missing a required value, is answered as unprocessable with
  the reason.
- **Major and full version** — the host lists each major it serves by a full version
  in major.minor.patch form, and the major is that version's first part. Every
  method answers at the same address at every major, and a call that names no major
  is answered at the oldest one listed.
- **Earlier answer** — a hub method always answers in the newest major's shape. A
  method whose answer changed declares, through hub_kernel-interface, how to turn its
  answer back into an older major's shape, and a call at an older major gets the
  answer passed through each of those from the newest down to the major named.
- **Unserved major** — a call naming a major the host does not list is answered as
  not acceptable, with a message naming the majors that are served.
- **No majors listed** — a host that lists no majors does no versioning: every call
  gets the method's own answer and no version is reported.
