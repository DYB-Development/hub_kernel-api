---
name: hub_kernel-api-develop
description: Use PROACTIVELY for calling a served hub over HTTP — listing the methods a caller may call at a hub's address, calling a read with GET, calling a write with POST, sending its values, naming the major version a client was built for with Accept-Version, reading the Api-Version a call was answered at, and reading its answer or error status — MUST BE USED instead of hand-writing a controller or endpoint per hub method, versioning the URL by hand, or guessing at the API's responses.
tools: Read, Write, Edit, Grep
scope: hub JSON API — serving a hub_kernel hub's exposed methods as a JSON API in a host Rails app, each call behind the host's own sign-in and hub_kernel-interface's permission check and account scope
---

This local writes client code against the three endpoints and three headers below and
follows the steps in order. Where a step names a decision, it asks the developer and does
not pick.

## What hub_kernel-api is

A Rails engine that answers HTTP calls to the exposed methods of the hubs a host serves,
each call made after the host's sign-in and checked and scoped by the permission check and
account scope that hub_kernel-interface holds. When the host lists major versions, every
method answers at the same address at every major, and the caller picks the major with a
request header. Use this local when writing a front end, mobile app, service or request
test that calls those methods, or when working out why a call answered as it did. Adding
the gem, choosing the served hubs, listing the majors and mounting the engine belong to the
install local.

## Interface

- `GET /<hub>` — lists the methods the signed-in caller may call on the hub at that
  address, for the caller's account, each as `{ "name", "takes", "verb" }`.
- `GET /<hub>/<method>` — calls an exposed read with the values sent in the query string
  and answers `{ "answer": <return value> }`.
- `POST /<hub>/<method>` — calls an exposed write with the values sent in the request body
  or query string and answers `{ "answer": <return value> }`.
- `Accept-Version` request header — names the major version the client was built for, as
  the bare major number, such as `Accept-Version: 1`.
- `Api-Version` response header — the full major.minor.patch version the call was answered
  at, such as `1.4.0`.
- `Vary` response header — `Accept-Version` on every answer from a host that lists majors,
  so a cache keeps one copy per major.

Every path is relative to the path the host mounted the engine at, such as
`/api/v1/hubs`.

## How to use it

1. Find the path the host mounted the API at in its `config/routes.rb`. Every URL
   below starts with it. If the API is not mounted, stop and use the install local.

2. Find the hub's address. A hub answers at its module name underscored, so `Supplies`
   answers at `supplies`, unless the host listed it under a name of its own, such as
   `{ "money" => Billing::Ledger }`, in which case it answers only at `money`. Read the
   host's served hubs list in its initializer to find it.

3. Find the majors the host serves in `HubKernel::Api.versions` in its initializer. Each
   entry is a `MajorVersion` with a full version such as `"2.0.1"`, and its major is the
   first number.

   - If the host lists no majors, skip step 4. The API ignores any `Accept-Version`
     header, every call answers with the method's own answer, and no answer carries an
     `Api-Version` header.
   - If the host lists majors, go to step 4.

4. Choose the major the client is built for, and send it on every request, hubs listing
   included:

   ```
   Accept-Version: 2
   ```

   Which major to pin is the developer's decision: ask. A new client normally pins the
   newest major listed. A request with no `Accept-Version` header is answered at the
   oldest major listed, so a client that omits it silently gets the oldest answer shape.
   Send the major alone, never the full version: `2`, not `2.0.1`.

   At an older major, a method answers in the shape it had at that major. A method whose
   answer changed declares its earlier answers on the hub, and the API converts the
   newest answer down to the major named. At the newest major, the method's own answer is
   returned. Write the client against the shape of the major it pins.

5. Authenticate the request the way the host's sign-in requires, such as a session
   cookie or a bearer token. Ask the developer which one the client uses. A request the
   host's sign-in refuses is answered by the host, with the host's own status, and
   reaches no hub.

6. List what the caller may call:

   ```
   GET /api/v1/hubs/supplies
   Accept-Version: 2
   ```

   ```json
   [{ "name": "price_of", "takes": ["item"], "verb": "GET" },
    { "name": "reorder", "takes": ["item", "quantity"], "verb": "POST" }]
   ```

   The list holds only the methods this caller is permitted on this account. Use `verb`
   to choose GET or POST, and `takes` for the value names the method accepts.

7. Call a read with GET, sending its values as query parameters:

   ```
   GET /api/v1/hubs/supplies/price_of?item=42
   Accept-Version: 2
   ```

   Query values arrive as strings.

8. Call a write with POST, sending its values as a JSON body with
   `Content-Type: application/json`, keyed directly by value name with no wrapping key:

   ```
   POST /api/v1/hubs/supplies/reorder
   Content-Type: application/json
   Accept-Version: 2

   { "item": 42, "quantity": 3 }
   ```

   Query parameters on a POST are sent to the method as well. Do not send a value whose
   name is not in `takes`.

9. Read the response by status:

   | Case | Status | Body |
   | --- | --- | --- |
   | The method answers | 200 | `{"answer": <return value>}` |
   | The hub is not served, the method is not exposed, the verb is wrong, or the permission check refuses the caller | 404 | `{"error": "Not found"}` |
   | The hub refuses the call, or a required value is missing | 422 | `{"error": "<reason>"}` |
   | A permitted call sends a value the method does not take | 422 | `{"error": "<method> does not take <values>"}` |
   | A record the call names does not exist | 404 | `{"error": "No <record> has the id <id>"}` |
   | `Accept-Version` names a major the host does not list | 406 | `{"error": "Major <n> is not served, the majors served are <majors>"}` |

   Show the `error` text of a 422 to the user, since it is the hub's reason. Treat
   `Not found` as a method that does not exist for this caller. Treat a 406 as a client
   built for a major the host no longer serves, and fix the pinned major rather than
   retrying.

10. Read the response headers from a host that lists majors:

    - `Api-Version` holds the full version the answer was given at, such as `2.0.1`, on
      every answer except a 406. Use it to log or show which version served the call.
    - `Vary: Accept-Version` is on every answer, the 406 included. Any cache between the
      client and the API must honour it.

11. For a request test in the host, sign in as a person with and without the permission,
    and assert the 200 answer for one and the `Not found` 404 for the other. When the
    host lists majors, also assert the `Api-Version` header for a named major, the
    answer shape at an older major for a method that declares earlier answers, and the
    406 for a major the host does not list.

## Conventions

- Never send GET to a write or POST to a read; the wrong verb is answered as not found,
  never as a method error.
- A forbidden method and a missing one both answer `Not found`, so a client cannot tell
  them apart, and must not try.
- The `answer` is the method's return value as JSON, converted to the named major's shape
  when the host lists majors; nothing else is added to it.
- The major is chosen by the `Accept-Version` header alone; never put a version in the
  path after the mount point or in a query parameter.
- A client against a host that lists majors always sends `Accept-Version`, and never
  relies on the oldest-major default.
- The account a call is made for comes from the host's sign-in, never from a value in the
  request.
- Only the methods a hub exposes are reachable; adding a method to the API means exposing
  it on the hub, not adding a route.
- Installing the gem, configuring it, choosing the served hubs, listing the majors and
  declaring a method's earlier answers are out of scope here.
