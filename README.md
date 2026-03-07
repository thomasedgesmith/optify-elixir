# Optify (Elixir / Phoenix)

Elixir client for [Optify](https://github.com/juharris/optify), powered by the upstream Rust crate via Rustler NIFs.

## High-level usage

Configure provider once at app level, then fetch options by feature names.

```elixir
# config/runtime.exs (or dev.exs/prod.exs)
config :optify, :provider,
  directory: "config/optify"

# Optional: validate feature files against a custom schema that extends
# Optify's upstream feature-file schema.
config :optify, :provider,
  directory: "config/optify",
  schema_path: "priv/schemas/optify_feature.schema.json"
```

Defaults:
- provider auto-loads at app startup
- provider auto-reloads in `:dev` when config files change

Then in code:

```elixir
options = Optify.get_options!(["feature_a", "feature_b"])

# atom keys by default for dot access
options.flow
options.flow.handler
```

`flow` is just a normal top-level key under `options` in your feature files.
No special key name is required.

The same default-provider shortcut pattern is available for provider introspection
such as `Optify.get_features/0`, `Optify.get_aliases/0`, and `Optify.get_feature_metadata/1`.

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

- Default-provider convenience:
  - `Optify.get_options/2`
  - `Optify.get_options!/2`
  - `Optify.get_features/0`
  - `Optify.get_aliases/0`
  - `Optify.get_features_and_aliases/0`
  - `Optify.get_canonical_feature_name/1`
  - `Optify.get_canonical_feature_name!/1`
  - `Optify.get_canonical_feature_names/1`
  - `Optify.get_canonical_feature_names!/1`
  - `Optify.get_feature_metadata/1`
  - `Optify.get_features_with_metadata/0`
  - `Optify.get_filtered_feature_names/1`
  - `Optify.get_filtered_feature_names/2`
  - `Optify.get_filtered_feature_names!/1`
  - `Optify.get_filtered_feature_names!/2`
  - `Optify.has_conditions/1`
- Provider builders:
  - `Optify.build/1`
  - `Optify.build_with_schema/2`
  - `Optify.build_from_directories/1`
  - `Optify.build_from_directories_with_schema/2`
- Provider-explicit APIs:
  - `Optify.get_options/4`
  - `Optify.get_options!/4`
  - `Optify.get_features/1`
  - `Optify.get_aliases/1`
  - `Optify.get_features_and_aliases/1`
  - `Optify.get_canonical_feature_name/2`
  - `Optify.get_canonical_feature_names/2`
  - `Optify.get_feature_metadata/2`
  - `Optify.get_features_with_metadata/1`
  - `Optify.get_filtered_feature_names/3`
  - `Optify.get_filtered_feature_names!/3`
  - `Optify.has_conditions/2`

## Development

```bash
mix deps.get
mix format
mix test
```
