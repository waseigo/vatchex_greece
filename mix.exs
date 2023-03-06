defmodule VatchexGreece.MixProject do
  use Mix.Project

  def project do
    [
      app: :vatchex_greece,
      version: "0.5.1",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),

      # Docs
      name: "VatchexGreece",
      source_url: "https://github.com/waseigo/vatchex_greece",
      homepage_url: "https://github.com/waseigo/vatchex_greece",
      docs: [
        main: "VatchexGreece", # The main page in the docs
        logo: "./logo.png",
        extras: ["README.md"]
      ]
    ]
  end

  defp description do
    """
    Library for fetching information on Greek companies based on their
    VAT number from the GSIS SOAP web service.
    """
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Isaak Tsalicoglou"],
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/waseigo/vatchex_greece"}
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :eex, :soap]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      {:soap, "~> 1.0"},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false},
    ]
  end
end
