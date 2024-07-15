defmodule Whenwhere.MixProject do
  use Mix.Project

  def project do
    [
      app: :whenwhere,
      version: "0.1.0",
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      # Docs
      name: "Whenwhere",
      description:
        "A small library for Nerves devices to check in with a Nerves Project hosted endpoint to help find themselves.",
      source_url: "https://github.com/nervescloud/whenwhere",
      docs: [
        # The main page in the docs
        main: "readme",
        extras: ["README.md"]
      ],
      package: [
        name: :whenwhere,
        licenses: ["Apache-2.0"],
        links: %{"GitHub" => "https://github.com/nervescloud/whenwhere"}
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:inets, :ssl]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.31", only: :dev, runtime: false}
    ]
  end
end
