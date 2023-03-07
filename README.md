# VatchexGreece

An Elixir library to easily pull company information from the SOAP web service of the Greek General Secretariat of Information Systems for Public Administration (GSIS) using the VAT ID (Αριθμός Φορολογικού Μητρώου, abbreviated as "ΑΦΜ" or "Α.Φ.Μ.").

Note: this project is a volunteer effort and not in any way affiliated with GSIS or the data service providers of the Greek Ministry of Finance.

## Installation

The package is [available in Hex](https://hex.pm/packages/vatchex_greece) and can be installed
by adding `vatchex_greece` to your list of dependencies in `mix.exs`. 


```elixir
def deps do
  [
    {:vatchex_greece, "~> 0.6.0"},
  ]
end
```

For parsing SOAP responses, [`Soap`](https://github.com/elixir-soap/soap) is used. Because `Soap` uses a `config/config.exs`, you need to add the following snippet to your application's `config/config.exs`:

```elixir
config :soap, :globals, version: "1.1"
```

## Standalone usage

Use [`VatchexGreece.get/4`](https://hexdocs.pm/vatchex_greece/VatchexGreece.html#get/4) (or its unsafe variant [`VatchexGreece.get!/4`](https://hexdocs.pm/vatchex_greece/VatchexGreece.html#get!/4)) with the target VAT ID plus your GSIS SOAP web service username, password, and source VAT ID associated with your authentication username and password (it's a legal requirement).

For repeated use with the same credentials it's more convenient to wrap [`VatchexGreece.get!/2`](https://hexdocs.pm/vatchex_greece/VatchexGreece.html#get/2) (or its unsafe variant [`VatchexGreece.get!/2`](https://hexdocs.pm/vatchex_greece/VatchexGreece.html#get!/2)) so that it automatically pulls these three credential parameters from a keyword list, or unpacks them from a keyword list or map; see below.


## Application configuration

Add the three configuration parameters to your application's `config.exs`, with these specific key names within the keyword list:

```elixir
config :my_app,
  vatchex_greece: [
    username: "foo",
    password: "bar",
    afmcalledby: "baz"
  ]
```

Note that `afmcalledby` must be a valid VAT ID, i.e. it must pass the [`VatchexGreece.Validate.valid?/1`](https://hexdocs.pm/vatchex_greece/VatchexGreece.Validate.html#valid?/1) checker. In any case, `get/4` performs a validity check on both the source and the target VAT IDs and only proceeds with the request preparation when both are valid.

There is also a `get/2` that takes a keyword list or map as its second argument, so that it's easier to use with the `config` above. You can call it with the target VAT ID as the first argument (with or without the "EL" prefix or a leading zero), and the keyword tuple or map pulled from your application's configuration as the second argument:

```elixir
    VatchexGreece.get("EL123456789", Application.fetch_env!(:my_app, :vatchex_greece))
```

Maybe wrap `get/2` so that you can simply call `vat.("EL123456789")` without providing the credentials every time, like so:

```elixir
vat = fn x when is_bitstring(x) -> 
  VatchexGreece.get(x, Application.fetch_env!(:my_app, :vatchex_greece))
  end
```

## Documentation

The docs can be found at <https://hexdocs.pm/vatchex_greece>.
