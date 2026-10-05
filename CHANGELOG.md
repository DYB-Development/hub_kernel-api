# Changelog

## [Unreleased]

## [0.1.0] - 2026-10-04

### Added
- `HubKernel::Api::Engine`, which answers each exposed method of each hub in `HubKernel::Api.hubs` at `/<hub>/<method>`, reads on GET and writes on POST.
- `HubKernel::Api.base_controller`, `person_method` and `account_method`, which name the host controller the API inherits from and the methods giving the person and account of each call.
