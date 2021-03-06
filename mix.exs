defmodule CyberSourceSDK.Mixfile do
  use Mix.Project

  def project do
    [
      app: :cybersource_sdk,
      version: "1.0.4",
      elixir: "~> 1.2",
      deps: deps(),
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
      {:httpoison, "~> 0.13"},
      {:poison, ">= 2.0.0"},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:bypass, "~> 0.6", only: :test}
    ]
  end
end
