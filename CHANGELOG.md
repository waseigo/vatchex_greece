# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.1.0] - 2026-06-26

### Added
- Optional `VatchexGreece.Prettify` module for reshaping fetch results into a more ergonomic form (`pretty: true` option on `fetch/1`).
  - Combines postal address fields into a `%{street_address: ..., raw: ...}` submap.
  - Adds `:afm_full` AFM digits).
  - Adds `:is_active` boolean derived from `:stop_date`.
  - Adds `:year_founded` integer from `:regist_date` (nil if unparseable).
  - Reshapes activities into `%{primary: map | nil, secondary: [map]}`, stripping internal `:prio`/`:prio_text`.
- Optional caching via Cachex v4 (`:cache` option on `fetch/1`).
- `VatchexGreece.Cache` protocol for custom cache adapters.
- VIES fallback when GSIS lookup fails (`fetch_vies_fallback: true`, requires `vatchex_vies`).
- Dedicated unit test suite (no external dependencies or live API calls).
- `DESIGN.md` architecture document.

### Changed
- Replaced HTTPoison with Req.
- New `fetch/1` and `fetch!/1` functions as the supported public API.
- `fetch!/1` raises `VatchexGreece.FetchError` on failure.
- Error responses normalized to consistent `%{code: atom | string, descr: string}` shape.
- Transport errors handled gracefully in `Request.post/1` instead of crashing.
- Structs (`APIauth`, `GSISdata`, `Results`, `NACEactivity`) made strictly internal (`@moduledoc false`).

### Removed
- Legacy `VatchexGreece.new/4` and `VatchexGreece.get/1` chainable API.
- `VatchexGreece.Validate.all_valid/1` from public API.
- Unused `require EEx` and `SweetXml` dependency from main module.

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

[Unreleased]: https://github.com/tisaak/vatchex_greece/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/tisaak/vatchex_greece/compare/v1.0.1...v1.1.0
[1.0.1]: https://github.com/tisaak/vatchex_greece/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/tisaak/vatchex_greece/compare/v0.8.1...v1.0.0
[0.8.1]: https://github.com/tisaak/vatchex_greece/compare/v0.8.0...v0.8.1
[0.8.0]: https://github.com/tisaak/vatchex_greece/compare/v0.7.0...v0.8.0
[0.7.0]: https://github.com/tisaak/vatchex_greece/releases/tag/v0.7.0
