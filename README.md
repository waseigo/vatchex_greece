# VatchexGreece

An Elixir library to easily pull company information from the SOAP web service of the Greek General Secretariat of Information Systems for Public Administration (GSIS) using the VAT ID (Αριθμός Φορολογικού Μητρώου, abbreviated as "ΑΦΜ" or "Α.Φ.Μ.").

Note: this project is a volunteer effort and not in any way affiliated with the data service providers of the Greek Ministry of Finance.

## Installation

The package is [available in Hex](https://hex.pm/packages/vatchex_greece) and can be installed
by adding `vatchex_greece` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:vatchex_greece, "~> 0.5.2"}
  ]
end
```

## Configuration

Setup `VatchexGreece` in your `config.exs`, and define the `username`, `password` and `afmCalledBy` parameters:

```elixir
config :vatchex_greece, :globals,
  gsis_wsdl_url: "https://www1.gsis.gr/webtax2/wsgsis/RgWsPublic/RgWsPublicPort?wsdl",
  xml_template: "priv/request.xml.eex",
  username: "",
  password: "",
  afmCalledBy: ""
```

## Documentation

The docs can be found at <https://hexdocs.pm/vatchex_greece>.

## TODO

- [x] Implement core functionality
- [x] Publish on hex.pm
- [ ] Implement testing functions
- [ ] Parse company activities and clean them up
- [ ] Set up CI

