# Changelog

## [Unreleased]

## [0.10.0] - 2026-10-29

### Added
- `HubKernel::Api.versions` lists the major versions a host serves as `HubKernel::Api::MajorVersion` entries, each with its full version in major.minor.patch form.
- A caller names a major in an `Accept-Version` request header, a call with no header is answered at the oldest major listed that is not retired, and every answer reports its full version in `Api-Version` and carries `Vary: Accept-Version`.
- A call naming an older major answers with the method's answer passed through each earlier answer its hub declares, newest first.
- A call naming a major the host does not list is refused with status 406 and `HubKernel::Api::UnservedMajorError`.
- A major can be listed `retired: true`, and a call or listing naming it is refused with status 410 and `HubKernel::Api::RetiredMajorError`.
- A major can be listed `deprecated: true` with `deprecated_on:` and `sunset:` dates, and answers at it carry RFC 9745 `Deprecation` and `Sunset` headers.
- Every answer at a major older than the newest carries an `Api-Newest-Version` header.
- Hub listings give each method's `answer_shape` at the major named, and a GET at the API's root address lists every served hub's methods with their shapes and the major's full version.
- `bin/rails hub_kernel_api:describe` writes one JSON description file per major not retired into `api_descriptions`.
- `bin/rails hub_kernel_api:check_descriptions` raises `HubKernel::Api::BreakingChangeError` when a major removes or renames something its committed file holds, or adds something without raising its minor, and the describe task refuses to write while the check would fail.
- `HubKernel::Api::TestHelper#assert_answer_shape` checks a method's answer against its shape at a major, using json_schemer from the host's test group.
- `HubKernel::Api.check!` names version mistakes at boot together with problems in the served list.

### Changed
- hub_kernel-api requires hub_kernel-interface 0.10.
- A host that lists no majors ignores `Accept-Version` and answers every call as before.

## [0.9.0] - 2026-10-14

### Changed
- A call is made for the person and account that `HubKernel::Interface.person_method` and `HubKernel::Interface.account_method` give when `HubKernel::Api.person_method` or `HubKernel::Api.account_method` is not set, and the JSON API's own setting is used when it is.
- hub_kernel-api requires hub_kernel-interface 0.9.

## [0.8.0] - 2026-10-07

### Changed
- `HubKernel::Api.hubs` reads and writes hub_kernel-interface's one served list, so hub_kernel-api and hub_kernel-mcp serve the same hubs from one setting.
- `HubKernel::Api.check!` runs hub_kernel-interface's check, and `HubKernel::Api::UnservableHubError` is another name for its error.
- A call sending a value its method is not listed with asks the permission check once, about that method alone.
- hub_kernel-api requires hub_kernel-interface 0.6.

## [0.7.0] - 2026-10-06

### Changed
- hub_kernel-api depends on hub_kernel-interface in place of hub_kernel, so an app serving hubs no longer installs hub_kernel through it.

## [0.6.0] - 2026-10-06

### Added
- hub_kernel-api is a the_local provider: installing it gives an app its info, install and develop agents.

## [0.5.0] - 2026-10-06

### Added
- `HubKernel::Api.check!`, which raises `HubKernel::Api::UnservableHubError` naming a served entry that exposes no methods, two served hubs at the same address, and each problem with a served hub's exposed list.

## [0.4.0] - 2026-10-06

### Added
- A GET at a served hub's address, `/<hub>`, lists the methods the caller may call on the account the host names, each with its name, the values it takes and its verb.

## [0.3.0] - 2026-10-06

### Changed
- A permitted call sending a value its method is not listed with is answered with status 422 naming each such value, where the value used to be dropped. A caller the permission check refuses is still answered as not found.
- hub_kernel-api requires hub_kernel 0.18.

## [0.2.0] - 2026-10-06

### Added
- An entry in `HubKernel::Api.hubs` may be a one-pair hash of an address name to a hub, which then answers at that name instead of its module name.

## [0.1.0] - 2026-10-04

### Added
- `HubKernel::Api::Engine`, which answers each exposed method of each hub in `HubKernel::Api.hubs` at `/<hub>/<method>`, reads on GET and writes on POST.
- `HubKernel::Api.base_controller`, `person_method` and `account_method`, which name the host controller the API inherits from and the methods giving the person and account of each call.
