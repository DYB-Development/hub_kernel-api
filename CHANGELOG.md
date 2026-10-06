# Changelog

## [Unreleased]

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
