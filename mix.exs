defmodule VatchexGreece.MixProject do
  use Mix.Project

  def project do
    [
      app: :vatchex_greece,
      version: "1.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      name: "VatchexGreece",
      source_url: "https://github.com/waseigo/vatchex_greece",
      homepage_url: "https://overbring.com/software/vatchex_greece/",
      docs: docs(),
      test_coverage: [summary: [threshold: 80]]
    ]
  end

  defp description do
    """
    An Elixir library to easily pull company information from the `RgWsPublic2` SOAP web service (new since 2023-04-20) of the Greek General Secretariat of Information Systems for Public Administration (GSIS) using the VAT ID (Αριθμός Φορολογικού Μητρώου, abbreviated as "ΑΦΜ" or "Α.Φ.Μ.").
    """
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README*", "LICENSE*", "llms.txt"],
      maintainers: ["Isaak Tsalicoglou"],
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/waseigo/vatchex_greece"}
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:eex, :logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:sweet_xml, "~> 0.7.3"},
      {:req, "~> 0.5"},
      {:cachex, "~> 4.1", only: [:dev, :test], runtime: false},
      {:vatchex_vies, "~> 1.0", optional: true},
      {:plug, "~> 1.4", only: :test, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.40.3", only: :dev, runtime: false, warn_if_outdated: true}
    ]
  end

  defp docs do
    [
      # The main page in the docs
      main: "VatchexGreece",
      logo: "./assets/logo.png",
      extras: ["README.md"]
      # Only the main VatchexGreece module is part of the public documented API.
      # All other modules are internal implementation details (@moduledoc false).
    ]
  end
end
