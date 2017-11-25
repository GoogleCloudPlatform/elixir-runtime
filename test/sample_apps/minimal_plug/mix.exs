defmodule MinimalPlug.Mixfile do
  use Mix.Project

  def project do
    [
      app: :minimal_plug,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :cowboy, :plug],
      mod: {MinimalPlug, []}
    ]
  end

  defp deps do
    [
      {:cowboy, "~> 1.0"},
      {:plug, "~> 1.0"}
    ]
  end
end
