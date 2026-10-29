---
name: hub_kernel-api-develop
description: Use PROACTIVELY for calling a served hub over HTTP — listing every served hub's methods and the version at the API's root address, listing the methods a caller may call at a hub's address, reading the JSON Schema of each method's answer from a listing, calling a read with GET, calling a write with POST, sending its values, naming the major version a client was built for with Accept-Version, reading the Api-Version a call was answered at, noticing from Api-Newest-Version that a newer major is served, noticing from Deprecation and Sunset that the pinned major is deprecated, when it was deprecated and when it stops being served, reading its answer or error status, handling a call refused because it names a retired major, writing each major's description file with the describe task, and checking a recorded answer against a description file without a running host — MUST BE USED instead of hand-writing a controller or endpoint per hub method, versioning the URL by hand, hand-writing a schema or type for a method's answer, hand-writing an API description file, or guessing at the API's responses.
tools: Read, Write, Edit, Grep
scope: hub JSON API — serving a hub_kernel hub's exposed methods as a JSON API in a host Rails app, each call behind the host's own sign-in and hub_kernel-interface's permission check and account scope
---

This local writes client code against the four endpoints, the six headers, the answer
shapes, the describe task and the description files below, and follows the steps in order.
Where a step names a decision, it asks the developer and does not pick.

## What hub_kernel-api is

A Rails engine that answers HTTP calls to the exposed methods of the hubs a host serves,
each call made after the host's sign-in and checked and scoped by the permission check and
account scope that hub_kernel-interface holds. When the host lists major versions, every
method answers at the same address at every major, and the caller picks the major with a
request header. A host can keep a major listed but mark it retired, and then every call
naming it is refused as gone. A host can also mark a major it still serves deprecated, and
must give the date it was deprecated and the date it stops being served, and every answer
at it then carries headers giving those dates. Every
answer at a major older than the newest carries a header naming the newest. A listing can give the JSON Schema of each method's answer at that major,
and a rake task writes the same description for each major into a file a client can use
without reaching a running host. Use this local when writing a front end, mobile app,
service or request test that calls those methods, when generating client types from the
answer shapes, when writing or using the description files, or when working out why a call
answered as it did. Adding the gem, choosing the served hubs, listing the majors, deprecating
or retiring a major, declaring
answer shapes and mounting the engine belong to the install local.

## Interface

- `GET /` — lists every served hub's methods the signed-in caller may call, keyed by the
  hub's address, with the full version the listing describes, as
  `{ "version", "hubs": { "<hub>": [...] } }`.
- `GET /<hub>` — lists the methods the signed-in caller may call on the hub at that
  address, for the caller's account, each as `{ "name", "takes", "verb", "answer_shape" }`.
- `GET /<hub>/<method>` — calls an exposed read with the values sent in the query string
  and answers `{ "answer": <return value> }`.
- `POST /<hub>/<method>` — calls an exposed write with the values sent in the request body
  or query string and answers `{ "answer": <return value> }`.
- `Accept-Version` request header — names the major version the client was built for, as
  the bare major number, such as `Accept-Version: 1`.
- `Api-Version` response header — the full major.minor.patch version the call was answered
  at, such as `1.4.0`, absent on a 406 or 410.
- `Api-Newest-Version` response header — the full version of the newest major the host
  lists, such as `2.0.1`, sent only when the answer was given at an older major.
- `Deprecation` response header — the date the major was deprecated, as `@` and the Unix
  seconds of that date's midnight UTC, such as `@1790726400`, sent only when the answer was
  given at a major the host marked deprecated.
- `Sunset` response header — the date a deprecated major stops being served, as an HTTP
  date such as `Wed, 31 Mar 2027 00:00:00 GMT`, sent only when the answer was given at a
  major the host marked deprecated.
- `Vary` response header — `Accept-Version` on every answer from a host that lists majors,
  refusals included, so a cache keeps one copy per major.
- `answer_shape` listing field — the JSON Schema of a method's answer at the major the
  listing describes, present only when one is declared for that major.
- `bin/rails hub_kernel_api:describe` — run in the host, writes one description file for
  each major the host lists that is not retired into the host's `api_descriptions` folder.
- `api_descriptions/v<major>.json` — one major's description, written for no retired major, `{ "version", "hubs":
  { "<hub>": [...] } }`, holding every served method at that major whatever any caller may
  call.

Every path in an endpoint is relative to the path the host mounted the engine at, such as
`/api/v1/hubs`. The `api_descriptions` folder is relative to the host's root.

## How to use it

1. Find the path the host mounted the API at in its `config/routes.rb`. Every URL
   below starts with it. If the API is not mounted, stop and use the install local.

2. Find the hub's address. A hub answers at its module name underscored, so `Supplies`
   answers at `supplies`, unless the host listed it under a name of its own, such as
   `{ "money" => Billing::Ledger }`, in which case it answers only at `money`. Read the
   host's served hubs list in its initializer to find it, or read the keys of the root
   address listing in step 6.

3. Find the majors the host lists in its initializer, where each is listed by its full
   version, such as `"2.0.1"`, and its major is the first number. A major listed with
   `retired: true` is retired: it stays listed, but every call naming it is refused with a
   410. A major listed with `deprecated: true` is still served in full, and always carries
   a `deprecated_on:` date on which it was deprecated and a `sunset:` date on which the host
   plans to stop serving it. A host whose majors hold a mistake, such as a deprecated major
   missing either date, a major listed twice, or every major retired, does not start, so at
   least one listed major is always served. The error of a 406 answer
   also names every major listed that is not retired, and the error of a 410 names the
   newest major listed.

   - If the host lists no majors, skip step 4. The API ignores any `Accept-Version`
     header on every endpoint, the root address included, every call answers with the
     method's own answer, every listing gives each method's own answer shape, no answer
     carries a version header or a `version` key, and the describe task writes no files.
   - If the host lists majors, go to step 4.

4. Choose the major the client is built for, and send it on every request, both listings
   included:

   ```
   Accept-Version: 2
   ```

   Which major to pin is the developer's decision: ask. A new client normally pins the
   newest major listed. Never pin a retired major, since every request naming it is
   refused with a 410. Avoid pinning a deprecated major in a new client, since the host
   plans to retire it. A request with no `Accept-Version` header is answered at the oldest
   major listed that is not retired, so a client that omits it silently gets that major's
   answer shape, and moves to a newer one when the host retires it. Send the major alone,
   never the full version: `2`, not `2.0.1`.

   At an older major, a method answers in the shape it had at that major. A method whose
   answer changed declares its earlier answers on the hub, and the API converts the
   newest answer down to the major named. At the newest major, the method's own answer is
   returned. Write the client against the shape of the major it pins.

5. Authenticate the request the way the host's sign-in requires, such as a session
   cookie or a bearer token. Ask the developer which one the client uses. A request the
   host's sign-in refuses is answered by the host, with the host's own status, and
   reaches no hub.

6. To discover everything the caller may call in one request, list the root address:

   ```
   GET /api/v1/hubs/
   Accept-Version: 1
   ```

   ```json
   { "version": "1.4.0",
     "hubs": { "supplies": [{ "name": "shelf_of", "takes": ["item"], "verb": "GET",
                              "answer_shape": { "type": "object", "required": ["shelf"] } }],
               "money": [] } }
   ```

   Each key under `hubs` is a served hub's address, and its list is that hub's listing as
   step 7 gives it. A served hub on which the caller may call nothing is listed with an
   empty list. `version` is the full version of the major the listing describes, and it is
   absent when the host lists no majors.

7. To list one hub, list its address:

   ```
   GET /api/v1/hubs/supplies
   Accept-Version: 2
   ```

   ```json
   [{ "name": "price_of", "takes": ["item"], "verb": "GET",
      "answer_shape": { "type": "object", "required": ["cents"] } },
    { "name": "reorder", "takes": ["item", "quantity"], "verb": "POST" }]
   ```

   The list holds only the methods this caller is permitted on this account. Use `verb`
   to choose GET or POST, and `takes` for the value names the method accepts.

8. Read each method's `answer_shape`, when present, as the JSON Schema of its `answer` at
   the major the listing was asked at. At the newest major it is the method's own declared
   shape. At an older major it is the shape declared for the nearest earlier answer at or
   after that major, or the method's own when it declares no earlier answer at or after
   that major. A method with no shape declared at that major has no `answer_shape` key, so
   treat its answer as untyped rather than reusing another major's shape.

   Whether the client validates answers against the shape or generates types from it is
   the developer's decision: ask. Fetch the shapes with the same `Accept-Version` the
   client sends on its calls, since a listing at another major gives another major's
   shapes.

9. To have every method's shape at each major without a request, write the description
   files in the host:

   ```sh
   bin/rails hub_kernel_api:describe
   ```

   The task creates the host's `api_descriptions` folder if it is missing and writes one
   file per major the host lists that is not retired, named after the major, such as `api_descriptions/v1.json`
   for a major listed as `"1.4.0"`:

   ```json
   { "version": "1.4.0",
     "hubs": { "supplies": [{ "name": "shelf_of", "takes": ["item"], "verb": "GET",
                              "answer_shape": { "type": "object", "required": ["shelf"] } }] } }
   ```

   `version` is the major's full version. Each key under `hubs` is a served hub's address,
   and each method is given as the root address listing gives it at that major, with
   `answer_shape` chosen by the rule in step 8 and absent when none is declared at that
   major. Unlike a listing, a file holds every method each served hub exposes, whatever
   any caller may call, and names no caller, so never read it as what a given caller may
   call. Use a listing for that.

   Run the task again after any change to a hub's exposed methods, their answer shapes,
   their earlier answers, the served hubs or the listed majors. Running it with no change
   writes identical files. The task overwrites the file of every major listed that is not
   retired and deletes no file, so delete by hand the file of a major the host has retired
   or no longer lists.

   Whether the host commits the files is the developer's decision: ask.

10. To check answers in a client repo without reaching a running host, copy in the file
    for the major the client pins, and check a recorded `answer` against the method's
    `answer_shape` from that file with a JSON Schema library. Which library to use is the
    developer's decision: ask. Copy the file again whenever the host rewrites it.

11. Call a read with GET, sending its values as query parameters:

    ```
    GET /api/v1/hubs/supplies/price_of?item=42
    Accept-Version: 2
    ```

    Query values arrive as strings.

12. Call a write with POST, sending its values as a JSON body with
    `Content-Type: application/json`, keyed directly by value name with no wrapping key:

    ```
    POST /api/v1/hubs/supplies/reorder
    Content-Type: application/json
    Accept-Version: 2

    { "item": 42, "quantity": 3 }
    ```

    Query parameters on a POST are sent to the method as well. Do not send a value whose
    name is not in `takes`.

13. Read the response by status:

    | Case | Status | Body |
    | --- | --- | --- |
    | The method answers, or a listing is given | 200 | `{"answer": <return value>}` for a call, the listing for a listing |
    | The hub is not served, the method is not exposed, the verb is wrong, or the permission check refuses the caller | 404 | `{"error": "Not found"}` |
    | The hub refuses the call, or a required value is missing | 422 | `{"error": "<reason>"}` |
    | A permitted call sends a value the method does not take | 422 | `{"error": "<method> does not take <values>"}` |
    | A record the call names does not exist | 404 | `{"error": "No <record> has the id <id>"}` |
    | `Accept-Version` names a major the host does not list, on any endpoint | 406 | `{"error": "Major <n> is not served, the majors served are <majors>"}` |
    | `Accept-Version` names a retired major, on any endpoint, whether or not the hub is served | 410 | `{"error": "Major <n> is no longer served, the newest major is <newest>"}` |

    Show the `error` text of a 422 to the user, since it is the hub's reason. Treat
    `Not found` as a method that does not exist for this caller. Treat a 406 as a client
    pinned to a major the host does not list, and a 410 as a client pinned to a major the
    host has retired. Fix the pinned major for either rather than retrying, and ask the
    developer which major to move the client to.

14. Read the response headers from a host that lists majors:

    - `Api-Version` holds the full version the answer was given at, such as `2.0.1`, on
      every answer except a 406 or a 410. Use it to log or show which version served the
      call.
    - `Api-Newest-Version` holds the full version of the newest major listed, such as
      `2.0.1`, on every answer given at an older major except a 406 or a 410. Its presence
      means a newer major is served than the one the client pins.
    - `Deprecation` holds the date the pinned major was deprecated, as `@` and the Unix
      seconds of that date's midnight UTC, such as `@1790726400` for 30 September 2026, as
      RFC 9745 defines it. It is on every answer given at a deprecated major except a 406
      or a 410. Its presence means the host plans to stop serving the pinned major.
    - `Sunset` holds the date the deprecated major stops being served, as an HTTP date such
      as `Wed, 31 Mar 2027 00:00:00 GMT`. It is on every answer that carries `Deprecation`,
      and on no other. After that date the host may retire the major, and calls naming it
      are then refused with a 410.
    - None of these headers changes the body of an answer. An answer at the newest major
      carries no `Api-Newest-Version`, and carries `Deprecation` and `Sunset` only when the
      newest major is itself deprecated.
    - `Vary: Accept-Version` is on every answer, the 406 and 410 included. Any cache between the
      client and the API must honour it.

    What the client does on `Api-Newest-Version` or `Deprecation`, such as logging a
    warning, showing a notice, or failing a check in CI, is the developer's decision: ask.
    Never move the pinned major automatically from these headers, since the answer shapes
    differ between majors.

15. For a request test in the host, sign in as a person with and without the permission,
    and assert the 200 answer for one and the `Not found` 404 for the other. When the
    host lists majors, also assert the `Api-Version` header for a named major, the
    answer shape at an older major for a method that declares earlier answers, the
    `answer_shape` a listing gives at that major, the root address listing's `version`,
    the `Api-Newest-Version` header at an older major and its absence at the newest, the
    `Deprecation` and `Sunset` header values at a deprecated major, the 406 for a major the
    host does not list, and the 410 for a retired major.

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
  relies on the default, and never sends a retired major.
- An `answer_shape` describes one major only; never apply a shape fetched at one major to
  answers at another, and never hand-write a shape the listing or a description file
  already gives.
- A description file is written by the describe task only; never edit one by hand, and
  never use one to decide what a caller may call.
- The account a call is made for comes from the host's sign-in, never from a value in the
  request.
- Only the methods a hub exposes are reachable; adding a method to the API means exposing
  it on the hub, not adding a route.
- `Api-Newest-Version`, `Deprecation` and `Sunset` are notices only; never treat an
  answer carrying them as an error, and never switch majors at runtime because of them.
- Installing the gem, configuring it, choosing the served hubs, listing the majors,
  deprecating or retiring a major, declaring a method's earlier answers and declaring answer shapes are out of scope here.
