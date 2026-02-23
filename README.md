# Optify (Elixir / Phoenix)

Elixir client for [Optify](https://github.com/juharris/optify), powered by the upstream Rust crate via Rustler NIFs.

## High-level usage

Configure provider once at app level, then fetch options by feature names.

```elixir
# config/runtime.exs (or dev.exs/prod.exs)
config :optify, :provider,
  directory: "config/optify"

# Auto-load once at app start
config :optify, :auto_load_default_provider, true

# Dev-only: auto-reload provider when config files change
config :optify, :auto_reload_default_provider, true
config :optify, :provider_poll_interval_ms, 1_000
```

Then in code:

```elixir
options = Optify.get_options!(["feature_a", "feature_b"])

# atom keys by default for dot access
options.flow
options.flow.handler
```

`flow` is just a normal top-level key under `options` in your feature files.
No special key name is required.

## Typed options (structs)

You can cast the merged options into a struct/module:

```elixir
defmodule MyApp.FlowOptions do
  defstruct [:handler, :timeout_ms]

  def from_optify(%{flow: flow}) do
    struct(__MODULE__, flow)
  end
end

flow = Optify.get_options!(["feature_a"], as: MyApp.FlowOptions)
```

If `as:` points to a struct module without `from_optify/1`, Optify will attempt direct key-based casting.

## API shape

- Tuple APIs:
  - `Optify.get_options/2`
  - `Optify.get_options/4`
- Bang APIs:
  - `Optify.get_options!/2`
  - `Optify.get_options!/4`
- Full config APIs:
  - `Optify.get_all_options/3`
  - `Optify.get_all_options!/3`
- Provider setup:
  - `Optify.build!/1`
  - `Optify.build_from_config!/0`
  - `Optify.load_default_provider!/0`

## Optional Plug integration

`Optify.Plug` is available, but optional.
If your app prefers explicit controller/service calls, you can skip the plug entirely.

## Development

```bash
mix deps.get
mix format
mix test
```
