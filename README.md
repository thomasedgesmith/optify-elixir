# Optify (Elixir / Phoenix)

Elixir client for [Optify](https://github.com/juharris/optify), powered by the upstream Rust crate via Rustler NIFs.

## Using with Phoenix

Configure the default provider in your Phoenix app config.
`optify-elixir` starts its own `Optify.DefaultProvider` process, so you do not need to add it to your app's supervisor tree manually.

```elixir
# config/config.exs
import Config

config :optify,
  auto_load_default_provider: true,
  auto_reload_default_provider: false
```

```elixir
# config/dev.exs
import Config

config :optify,
  auto_reload_default_provider: true
```

```elixir
# config/runtime.exs
import Config

config :optify, :provider,
  directory:
    System.get_env("OPTIFY_CONFIG_DIR") ||
      Application.app_dir(:my_app, "priv/optify")

# Optional: validate feature files against a custom schema that extends
# Optify's upstream feature-file schema.
config :optify, :provider,
  directory:
    System.get_env("OPTIFY_CONFIG_DIR") ||
      Application.app_dir(:my_app, "priv/optify"),
  schema_path:
    System.get_env("OPTIFY_SCHEMA_PATH") ||
      Application.app_dir(:my_app, "priv/optify_schema.json")
```

Recommended behavior:
- always auto-load the default provider
- only auto-reload from disk in `:dev`
- resolve the config path in `runtime.exs`

## Feature files

Point `:provider` at a directory of feature files. Feature names come from the relative file path without the extension.

Example files:

```json
// priv/optify/feature_a.json
{
  "metadata": {
    "aliases": ["A"]
  },
  "options": {
    "flow": {
      "handler": "a",
      "timeout_ms": 100
    }
  }
}
```

```yaml
# priv/optify/feature_b.yaml
metadata:
  aliases:
    - "B"
options:
  flow:
    handler: "b"
    timeout_ms: 200
```

That gives you:
- canonical feature names: `"feature_a"` and `"feature_b"`
- aliases: `"A"` and `"B"`

When you request both features, later features override earlier ones.

## Loading from features

Fetch merged options by feature name using the default provider:

```elixir
options = Optify.get_options!(["feature_a", "feature_b"])

# atom keys by default for dot access
options.flow
options.flow.handler
```

`flow` is just a normal top-level key under `options` in your feature files.
No special key name is required.

Aliases work too:

```elixir
options = Optify.get_options!(["A", "B"])
options.flow.handler
```

You can also fetch a specific top-level key with the explicit provider API:

```elixir
provider = Optify.build!(Application.app_dir(:my_app, "priv/optify"))

flow = Optify.get_options!(provider, "flow", ["feature_a", "feature_b"])
flow["handler"]
```

The same default-provider shortcut pattern is available for provider introspection
such as `Optify.get_features/0`, `Optify.get_aliases/0`, and `Optify.get_feature_metadata/1`.

## Dumping a resolved feature

When a feature is spread across many imported files, you can dump the resolved merged output for review:

```bash
mix optify.dump_feature feature_a
mix optify.dump_feature A --output tmp/optify/feature_a.json
mix optify.dump_feature feature_a --key flow
```

The task:
- uses the loaded default provider when available
- otherwise loads the default provider from your configured `:optify, :provider`
- resolves aliases to canonical feature names
- applies imports before dumping the merged result

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
