<img src="./assets/logo.png" width="100" height="100">

# VatchexGreece

An Elixir library to easily pull company information from the `RgWsPublic2` SOAP web service (new since 2023-04-20) of the Greek General Secretariat of Information Systems for Public Administration (GSIS) using the Tax Identification Number (_Αριθμός Φορολογικού Μητρώου_, abbreviated as "ΑΦΜ" or "Α.Φ.Μ.").

Note: this project is a volunteer effort and not in any way affiliated with GSIS or the data service providers of the Greek Ministry of Finance.

## Installation

The package is [available on Hex](https://hex.pm/packages/vatchex_greece) and can be installed
by adding `vatchex_greece` to your list of dependencies in `mix.exs`.

```elixir
def deps do
  [
    {:vatchex_greece, "~> 1.1"},
  ]
end
```

## Usage

```elixir
{:ok, data} = VatchexGreece.fetch(
  afm_called_for: "998144460",
  username: "your_token_username",
  password: "your_special_access_code",
  afm_called_by: "your_own_afm"
)
```

Returns a map with company information (onomasia, address, registration date, NACE activities, etc.) or `{:error, errors}` with validation/service error details.

Refer to the [documentation on HexDocs](https://hexdocs.pm/vatchex_greece/VatchexGreece.html) for the full API reference.

### Caching

Pass a `:cache` option to enable caching of successful lookups:

```elixir
VatchexGreece.fetch(
  afm_called_for: "998144460",
  username: "your_token_username",
  password: "your_special_access_code",
  afm_called_by: "your_own_afm",
  cache: VatchexGreece.CachexCache
)
```

You must have a Cachex instance running in your supervision tree. See [hexdocs.pm/cachex](https://hexdocs.pm/cachex) for setup.

## Testing

```sh
mix test
```

56 unit tests, no external dependencies or live service calls. Covers VAT ID validation, XML response parsing, SOAP envelope generation, pipeline error handling, and caching behavior.

## Changelog

### v1.0.0

#### Breaking changes vs. v0.8.0

The legacy pipeline API has been removed for the 1.0 release.

- `VatchexGreece.new/4` and `VatchexGreece.get/1` are gone.
- `VatchexGreece.Validate.all_valid/1` is no longer public (internal validation logic remains private).
- The top-level legacy structs (APIauth, GSISdata, Results, NACEactivity) are now strictly internal (@moduledoc false) and no longer referenced in public documentation.
- Only the high-level `fetch/1` / `fetch!/1` API is part of the supported public surface.
- `fetch!/1` now raises `VatchexGreece.FetchError`.
- All other modules (`VatchexGreece.Request`, `VatchexGreece.Processing`, `VatchexGreece.Validate`, and the legacy structs) are now strictly internal (`@moduledoc false`) and hidden from generated documentation.
- The internal pipeline (accumulator + steps) remains but is not part of the public API.

#### Improvements

- Log info, error and debug messages for some situations.
- Always send `as_on_date` (today) in requests, to match the reference Java client implementation.
- Post requests to the service endpoint (without `?wsdl`) instead of the WSDL URL.
- Properly detect and return service errors from the `error_rec` in responses (previously, errors from the GSIS service would result in `{:ok, %{... all nils ...}}` with only `as_on_date` populated, masking the actual error).
- Removed early string-based auth error check in favor of general service error handling (auth errors now surface with their `service_error` code and Greek description from the service).

### v0.8.0

- Replaced [HTTPoison](https://hex.pm/packages/httpoison) with [Req](https://hex.pm/packages/req).
- New `fetch/1` and `fetch!/1` functions that deprecate the chaining of `new/4` and `get/1`.

### v0.7.0

- Now compatible with the `RgWsPublic2` SOAP web service (new since 2023-04-20).
- Now possible to make SOAP API calls using different credentials in `%Auth{}` structs, e.g. for multi-tenant setups.
- Now needs no application setup in `config.exs` or `mix.exs`, thanks to getting rid of the [Soap](https://github.com/elixir-soap/soap) library due to parsing issues, and because it seems abandoned and not particularly robust to begin with.
- XML parsing is now handled directly with [SweetXml](https://hexdocs.pm/sweet_xml/SweetXml.html).
- Actual logging of errors in the `%Results{}` struct means you can find out what went wrong.
- Actual handling of errors (with `{:ok, ...}` and `{:error, ...}` tuples) along the pipeline across all modules means that no API call or parsing of the XML response body is made unless no errors have popped up.

## Documentation

The docs can be found at <https://hexdocs.pm/vatchex_greece>. There's also an [Elixir Forum thread](https://elixirforum.com/t/vatchexgreece-a-library-for-retrieving-greek-company-info-from-the-soap-web-service-of-gsis-using-the-vat-id/54425).
