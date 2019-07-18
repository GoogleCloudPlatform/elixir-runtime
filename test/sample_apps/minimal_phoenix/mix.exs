defmodule MinimalPhoenix.Mixfile do
  use Mix.Project

  def project do
    [
      app: :minimal_phoenix,
      version: "0.0.1",
      elixir: "~> 1.7",
      compilers: [:phoenix] ++ Mix.compilers,
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      mod: {MinimalPhoenix.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp deps do
    [
      {:phoenix, "~> 1.3.0"},
      {:phoenix_pubsub, "~> 1.0"},
      {:phoenix_html, "~> 2.10"},
      {:plug_cowboy, "~> 1.0"},
      {:distillery, "~> 1.5"}
    ]
  end
end
