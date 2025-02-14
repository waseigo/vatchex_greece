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
    {:vatchex_greece, "~> 0.8"},
  ]
end
```

## Usage

Refer to the [documentation on HexDocs](https://hexdocs.pm/vatchex_greece/VatchexGreece.html).

## Changelog

### v0.8.0

- Replaced [HTTPoison](https://hex.pm/packages/httpoison) with [Req](https://hex.pm/packages/req).
- New `fetch/1` and `fetch!/1` functions that deprecate the chaining of `new/4` and `get/1`.

### v0.7.0

- Now compatible with the `RgWsPublic2` SOAP web service (new since 2023-04-20).
- Now possible to make SOAP API calls using different credentials in `%Auth{}` structs, e.g. for multi-tenant setups.
- Now needs no application setup in `config.exs` or `mix.exs`, thanks to getting rid of the [Soap](https://github.com/elixir-soap/soap) library due to parsing issues, and because it seems abandoned and not particularly robust to begin with.
- XML parsing is now handled directly with [SweetXml](https://hexdocs.pm/sweet_xml/SweetXml.html).
- Actual logging of errors in the `%Results{}` struct means you can find out what went wrong.
- Actual handling of errors (with `{:ok, ...}` and `{:error, ...}` tuples along the pipeline across all modules means that no API call or parsing of the XML response body is made unless no errors have popped up.

## Documentation

The docs can be found at <https://hexdocs.pm/vatchex_greece>. There's also an [Elixir Forum thread](https://elixirforum.com/t/vatchexgreece-a-library-for-retrieving-greek-company-info-from-the-soap-web-service-of-gsis-using-the-vat-id/54425).

## Donate

Has this library been useful for your project? 

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/V7V119L07A)
