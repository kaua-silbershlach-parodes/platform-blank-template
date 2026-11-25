defmodule MachineryBackend.MixProject do
  use Mix.Project

  def project do
    [
      app: :machinery_backend,
      version: "1.0.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: []
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {MachineryBackend.Application, []}
    ]
  end
end
