defmodule Optify.MixProject do
  use Mix.Project

  def project do
    [
      app: :optify,
      version: File.read!(Path.join(__DIR__, "VERSION")) |> String.trim(),
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Elixir client for Optify with precompiled Rustler NIFs",
      docs: docs(),
      name: "Optify",
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
      {:rustler_precompiled, "~> 0.8"},
      {:rustler, ">= 0.0.0", optional: true},
      {:jason, "~> 1.4"},
      {:file_system, "~> 1.1"},
      {:ex_doc, "~> 0.40", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "LICENSE"],
      source_ref: source_ref()
    ]
  end

  defp source_ref do
    System.get_env("GITHUB_SHA") || "main"
  end

  defp package do
    [
      files: ~w(
          lib
          mix.exs
          VERSION
          README.md
          LICENSE
          native/optify_nif/Cargo.toml
          native/optify_nif/Cargo.lock
          native/optify_nif/rust-toolchain.toml
          native/optify_nif/src
        ) ++ Path.wildcard("checksum-*.exs"),
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/thomasedgesmith/optify-elixir"}
    ]
  end
end
