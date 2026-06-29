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

## Error shape

`fetch/1` and `fetch!/1` always return errors as `{:error, map}` with a consistent shape:

```elixir
{:error, %{code: <atom | string>, descr: <string>}}
```

| code | descr | meaning |
|------|-------|---------|
| `:invalid_vat` | `"Invalid target VAT ID: ..."` | VAT ID failed checksum/length check |
| `:http_not_ok` | `"HTTP status code 500 (not OK)"` | Non-200 HTTP response |
| `:transport_error` | `"Transport error: ..."` | Network failure (DNS, timeout, refused) |
| `"1001"` | `"Λάθος στοιχεία πρόσβασης"` | GSIS service error (code from API) |

Internal errors use atoms for `:code`. GSIS service errors use the string code returned by the API.

Refer to the [documentation on HexDocs](https://hexdocs.pm/vatchex_greece/VatchexGreece.html) for the full API reference.

## Usage with caching

Optional caching is available via [Cachex](https://hex.pm/packages/cachex) v4.x. Successful lookups are cached for a configurable TTL; errors are never cached.

### Setup

1. Add `cachex` to your dependencies:

```elixir
# mix.exs
{:cachex, "~> 4.1"}
```

2. Start a Cachex instance in your supervision tree:

```elixir
# application.ex
children = [
  {Cachex, name: :vatchex_greece, limit: 10_000},
  ...
]
```

3. Pass the cache adapter to `fetch/1` or `fetch!/1`:

```elixir
VatchexGreece.fetch(
  afm_called_for: "998144460",
  username: "your_token_username",
  password: "your_special_access_code",
  afm_called_by: "your_own_afm",
  cache: VatchexGreece.CachexCache
)
```

### Configuration

```elixir
# config/config.exs
config :vatchex_greece, :cache_name, :vatchex_greece  # Cachex cache name (default: :vatchex_greece)
config :vatchex_greece, :cache_ttl, 3_600_000       # TTL in milliseconds (default: 1 hour)
```

### Behavior

- Only successful results (`{:ok, data}`) are cached. Validation failures, HTTP errors, and service errors always hit the API.
- Cache keys are based on the target and source VAT IDs, not credentials.
- If Cachex is not started or not in the dependency list, the `:cache` option is silently ignored.
- You can provide your own cache adapter by implementing the `VatchexGreece.Cache` protocol.

## Testing

```sh
mix test
```

84 unit tests, no external dependencies or live service calls. Covers VAT ID validation, XML response parsing, SOAP envelope generation, pipeline error handling, caching behavior, pretty result reshaping, and VIES fallback.

## What's new

**v1.1.0** — Optional `pretty: true` mode, Cachex caching, VIES fallback, `Req.Test` adapters, truly optional Cachex, `vatchex_vies` from Hex, `llms.txt`, coverage threshold 80%.

See [CHANGELOG.md](CHANGELOG.md) for the full release history.

## llms.txt

This project includes an `llms.txt` file at the project root — a self-contained summary of the library's API surface for AI assistants and code generation tools. See the [llmstxt.org](https://llmstxt.org) specification for details.

## Support

If this library saves you time or helps your project, consider saying thanks by purchasing a copy of [**Northwind Elixir Traders**](https://leanpub.com/northwind-elixir-traders), an exploratory-learning book that teaches Elixir, Ecto, and SQLite all in one hands-on project, with its [source code](https://github.com/waseigo/northwind_elixir_traders) released under the Apache-2.0 License.

<a href="https://leanpub.com/northwind-elixir-traders">
  <img src="https://raw.githubusercontent.com/waseigo/northwind_elixir_traders/main/etc/northwind-elixir-traders-cover.jpg"
       width="200"
       alt="Northwind Elixir Traders cover">
</a>

See what readers are saying on the [book's ElixirForum thread](https://elixirforum.com/t/northwind-elixir-traders-pragprog/70887).

## Documentation

The docs can be found at <https://hexdocs.pm/vatchex_greece>. There's also an [Elixir Forum thread](https://elixirforum.com/t/vatchexgreece-a-library-for-retrieving-greek-company-info-from-the-soap-web-service-of-gsis-using-the-vat-id/54425).
