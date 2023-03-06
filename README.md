# VatchexGreece

An Elixir library to easily pull company information from the SOAP web service of the Greek General Secretariat of Information Systems for Public Administration (GSIS) using the VAT ID (Αριθμός Φορολογικού Μητρώου, abbreviated as "ΑΦΜ" or "Α.Φ.Μ.").


## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `vatchex_greece` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:vatchex_greece, "~> 0.5.1"}
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
- [ ] Publish on hex.pm
- [ ] Implement testing functions
- [ ] Parse company activities and clean them up
- [ ] Set up CI

