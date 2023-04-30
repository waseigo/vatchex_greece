<img src="./assets/logo.png" width="100" height="100">

# VatchexGreece

An Elixir library to easily pull company information from the `RgWsPublic2` SOAP web service (new since 2023-04-20) of the Greek General Secretariat of Information Systems for Public Administration (GSIS) using the VAT ID (Αριθμός Φορολογικού Μητρώου, abbreviated as "ΑΦΜ" or "Α.Φ.Μ.").

Note: this project is a volunteer effort and not in any way affiliated with GSIS or the data service providers of the Greek Ministry of Finance.

## Installation

The package is [available in Hex](https://hex.pm/packages/vatchex_greece) and can be installed
by adding `vatchex_greece` to your list of dependencies in `mix.exs`. 


```elixir
def deps do
  [
    {:vatchex_greece, "~> 0.7.0"},
  ]
end
```

## Usage

Use [`VatchexGreece.new/4`](https://hexdocs.pm/vatchex_greece/VatchexGreece.html#new/4) with the target VAT ID plus your GSIS SOAP web service username, password, and source VAT ID associated with your authentication username and password (it's a legal requirement). This defines a clean new `%Results{}` struct containing the filled-in `%Auth{}` struct and the prepared `%GSISdata{}` struct. The `%Results{}` struct and its contents will be progressively filled in by the function calls within [`VatchexGreece.get/1`](https://hexdocs.pm/vatchex_greece/VatchexGreece.html#get/1).

## Improvements since v0.6.0

* Now compatible with the `RgWsPublic2` SOAP web service (new since 2023-04-20).
* Now possible to make SOAP API calls using different credentials in `%Auth{}` structs, e.g. for multi-tenant setups.
* Now needs no application setup in `config.exs` or `mix.exs`, thanks to getting rid of the [Soap](https://github.com/elixir-soap/soap) library due to parsing issues, and because it seems abandoned and not particularly robust to begin with.
* XML parsing is now handled directly with [SweetXml](https://hexdocs.pm/sweet_xml/SweetXml.html).
* Actual logging of errors in the `%Results{}` struct means you can find out what went wrong.
* Actual handling of errors (with `{:ok, ...}` and `{:error, ...}` tuples along the pipeline across all modules means that no API call or parsing of the XML response body is made unless no errors have popped up.

## Documentation

The docs can be found at <https://hexdocs.pm/vatchex_greece>.
