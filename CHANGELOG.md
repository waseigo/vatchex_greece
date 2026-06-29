# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] - 2026-06-30

### Added

- `is_active` boolean field in the response map — `true` when `stop_date` is nil (company appears active), `false` when `stop_date` contains a date string.

## [1.1.1] - 2026-06-30

### Added

- `address_collapsed` field in the response map — single-line single-string version of the postal address, collapsed from the individual `postal_address`/`postal_address_no`/`postal_zip_code`/`postal_area_description` fields.

## [1.1.0] - 2026-06-29

### Added

- Optional `VatchexGreece.Prettify` module for reshaping fetch results into a more ergonomic form (`pretty: true` option on `fetch/1`).
  - Combines postal address fields into a `%{street_address: ..., raw: ...}` submap.
  - Adds `:afm_full` AFM digits.
  - Adds `:is_active` boolean derived from `:stop_date`.
  - Adds `:year_founded` integer from `:regist_date` (nil if unparseable).
  - Reshapes activities into `%{primary: map | nil, secondary: [map]}`, stripping internal `:prio`/`:prio_text`.
- Optional caching via Cachex v4 (`:cache` option on `fetch/1`).
- `VatchexGreece.Cache` protocol for custom cache adapters.
- VIES fallback when GSIS lookup fails (`fetch_vies_fallback: true`, requires `vatchex_vies`).
- Dedicated unit test suite (no external dependencies or live API calls).
- `DESIGN.md` architecture document.
- `Req.Test` adapter support for isolated HTTP stubbing in tests (`:test_adapter` option on `fetch/1`).
- `llms.txt` at project root — self-contained AI summary of the library API surface.
- Documented config defaults in `config/config.exs`.
- `{:plug, "~> 1.4"}` dependency for `:test` environment (required by `Req.Test`).
- Cache protocol `defimpl for: Atom` moved from `test_cache.ex` to `cache.ex` with `Code.ensure_loaded?` guards (matches vatchex_vies pattern).

### Changed

- Replaced HTTPoison with Req.
- New `fetch/1` and `fetch!/1` functions as the supported public API.
- `fetch!/1` raises `VatchexGreece.FetchError` on failure.
- Error responses normalized to consistent `%{code: atom | string, descr: string}` shape.
- Transport errors handled gracefully in `Request.post/1` instead of crashing.
- Structs (`APIauth`, `GSISdata`, `Results`, `NACEactivity`) made strictly internal (`@moduledoc false`).
- `vatchex_vies` dependency: `path: "../vatchex_vies"` → `"~> 1.0"` (fetched from Hex).
- `Cachex` dependency: removed from prod deps, now `only: [:dev, :test]` (truly optional).
- Test HTTP stubbing: replaced global `stub_endpoint`/`restore_endpoint` with per-test `Req.Test` adapters (no shared state, no real network calls).
- Coverage threshold raised from 70% to 80%.
- `VatchexVies.lookup` now receives `:test_adapter` from fetch opts for VIES fallback testing.
- `stub_endpoint/1` and `restore_endpoint/1` removed from `Request` module (replaced by `Req.Test` adapters).
- `do_post_with_request/2` removed (tests go through `fetch/1` with adapters).
- `CachexCache` defimpl for `VatchexGreece.CachexCache` moved from `cachex_cache.ex` into protocol dispatch in `cache.ex`.

### Removed

- Legacy `VatchexGreece.new/4` and `VatchexGreece.get/1` chainable API.
- `VatchexGreece.Validate.all_valid/1` from public API.
- Unused `require EEx` and `SweetXml` dependency from main module.
- Global state manipulation functions from `Request` (`stub_endpoint`/`restore_endpoint`).
- `@spec` annotation from `Prettify.pretty/1`.
- `vatchex_greece_transport_error_test.exs` (transport error tests now use adapters in main test suite).
- Outdated error key docs from `FetchError` docstring.

## [1.0.1] - 2026-06-26

### Fixed

- Table alignment in DESIGN.md.

## [1.0.0] - 2026-06-04

### Breaking

- Legacy pipeline API removed: `new/4`, `get/1`, and `Validate.all_valid/1` are gone.
- Internal structs (`APIauth`, `GSISdata`, `Results`, `NACEactivity`) are no longer part of the public surface.
- Only `fetch/1` and `fetch!/1` remain as the supported public API.
- `fetch!/1` now raises `VatchexGreece.FetchError` instead of returning an error tuple.

### Added

- Debug, info, and error logging throughout the pipeline.
- `as_on_date` always sent in requests (matches reference Java client).
- Proper detection of service errors from `error_rec` in responses (previously masked as maps full of nils).
- Unit test suite (48 tests).

### Changed

- Requests posted to the service endpoint URL directly (without `?wsdl`).
- Guards tightened from `is_bitstring/1` to `is_binary/1`.
- Auth errors no longer hard-coded; all service errors surface uniformly via the general error handling path.

## [0.8.1] - 2024-08-20

### Changed

- Relaxed Req dependency requirement to `~> 0.5`.

## [0.8.0] - 2024-08-19

### Changed

- Replaced HTTPoison with Req.
- Introduced `fetch/1` and `fetch!/1` to replace chaining `new/4` and `get/1`.

## [0.7.0] - 2023-04-30

### Changed

- Migrated to the `RgWsPublic2` SOAP web service (new since 2023-04-20, replacing the deprecated v1).
- Now supports per-request credentials via separate `%Auth{}` structs (multi-tenant setups).
- Dropped the Soap library (abandoned, parsing issues); XML parsing now done directly with SweetXml.
- No application setup required in `config.exs` or `mix.exs`.

### Added

- Structured error handling with `{:ok, ...}` / `{:error, ...}` tuples across the entire pipeline.
- Error details stored in `%Results{}` struct for inspection.
- Logging of errors in the results accumulator.

## [0.6.0] - 2023-03-08

### Added

- Public validation functions with tuple and bang variants.
- Convenience wrappers `get/2`, `get!/2` (preserve AFM) and `get/4`, `get!/4` (custom auth).
- XML template compiled into a function at compile time (EEx).

### Changed

- Fixed error handling to propagate properly through downstream functions.
- Renamed `Processing` module (disambiguated from OTP `Process`).
- Removed dependency on values in `config.exs`.

[Unreleased]: https://github.com/tisaak/vatchex_greece/compare/v1.2.0...HEAD
[1.2.0]: https://github.com/tisaak/vatchex_greece/compare/v1.1.1...v1.2.0
[1.1.1]: https://github.com/tisaak/vatchex_greece/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/tisaak/vatchex_greece/compare/v1.0.1...v1.1.0
[1.0.1]: https://github.com/tisaak/vatchex_greece/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/tisaak/vatchex_greece/compare/v0.8.1...v1.0.0
[0.8.1]: https://github.com/tisaak/vatchex_greece/compare/v0.8.0...v0.8.1
[0.8.0]: https://github.com/tisaak/vatchex_greece/compare/v0.7.0...v0.8.0
[0.7.0]: https://github.com/tisaak/vatchex_greece/releases/tag/v0.7.0
