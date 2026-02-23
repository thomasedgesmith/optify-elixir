defmodule Optify.MixProject do
  use Mix.Project

  def project do
    [
      app: :optify,
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Elixir/Phoenix client for Optify powered by the Rust crate",
      package: package(),
      source_url: "https://github.com/thomasedgesmith/optify-elixir"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Optify.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:rustler, "~> 0.37", runtime: false},
      {:jason, "~> 1.4"},
      {:plug, "~> 1.15"},
      {:file_system, "~> 1.1"}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/thomasedgesmith/optify-elixir"}
    ]
  end
end
