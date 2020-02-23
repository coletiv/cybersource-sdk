defmodule CyberSourceSDK.Mixfile do
  use Mix.Project

  def project do
    [
      app: :cybersource_sdk,
      version: "1.0.5",
      elixir: "~> 1.2",
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      package: [
        maintainers: ["David Magalhães"],
        licenses: ["MIT"],
        links: %{github: "https://github.com/coletiv/cybersource-sdk"}
      ],
      description: """
      Non-official library used to call WSDL SOAP Services of CyberSource.
      """,

      # Docs
      name: "CyberSource SDK",
      source_url: "https://github.com/coletiv/cybersource-sdk",
      docs: [
        extras: ["README.md"]
      ]
    ]
  end

  def application do
    [
      mod: {CyberSourceSDK, []},
      applications: [
        :logger,
        :inets,
        :ssl,
        :sweet_xml,
        :poison,
        :httpoison
      ]
    ]
  end

  defp deps do
    [
      {:sweet_xml, "~> 0.6"},
      {:httpoison, "~> 1.6"},
      {:poison, ">= 2.0.0"},
      {:cowboy, "~> 1.1.2"},
      {:plug_cowboy, "~> 1.0"},
      {:exvcr, "~> 0.10.3", only: [:dev, :test]},
      {:excoveralls, "~> 0.11.1", only: [:dev, :test]},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:bypass, "~> 0.6", only: :test}
    ]
  end
end
