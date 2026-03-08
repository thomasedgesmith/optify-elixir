# Optify

Optify is an Elixir client for [Optify](https://github.com/juharris/optify), powered by the upstream Rust crate via Rustler NIFs.

## Precompiled NIFs

Optify ships precompiled NIFs for common macOS and Linux targets, so consumers usually do not need Rust installed.
Unsupported targets fall back to a local Rust build, and you can also force a local build explicitly with:

```bash
OPTIFY_BUILD=1 mix compile
```

## Usage

Configure the default provider in your app config.
Optify starts its own default provider process, so you do not need to add it to your app's supervisor tree manually.
The default provider auto-loads automatically once `:optify, :provider` is configured.

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
- rely on the built-in default provider auto-load
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

The high-level `Optify.get_options!/1` and `Optify.get_options!/2` APIs also hydrate
known nested option paths with `nil` defaults. If another feature defines
`options.flow.handler`, then `options.flow.handler` stays safe even when the selected
feature set does not define `flow` at all.

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

The same default-provider shortcut pattern is available for provider introspection,
including feature listing, alias lookup, and feature metadata access.

## Dumping a resolved feature

When a feature is spread across many imported files, you can dump the resolved merged output for review:

```bash
mix optify.dump feature_a
mix optify.dump A --output tmp/optify/feature_a.json
mix optify.dump feature_a --key flow
```

The task:
- uses the loaded default provider when available
- otherwise loads the default provider from your configured `:optify, :provider`
- resolves aliases to canonical feature names
- applies imports before dumping the merged result

## Advanced: typed options

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

This is optional. The default `get_options!` API already returns dot-friendly maps,
so you only need `as:` when you specifically want a typed struct/module.

If `as:` points to a struct module without `from_optify/1`, Optify will attempt direct key-based casting.

## API shape

- Default-provider convenience: merged option lookup, feature listing, alias lookup, canonical name resolution, metadata lookup, filtering, and condition checks.
- Provider builders: construct a provider from one directory, multiple directories, and optional schema paths.
- Provider-explicit APIs: the same capabilities are available when you pass an explicit provider value.

## Development

Use a local Rust build while developing this package:

```bash
mix deps.get
OPTIFY_BUILD=1 mix format
OPTIFY_BUILD=1 mix test
```

## Releasing

The release flow for precompiled NIFs is:

1. bump `VERSION`
2. create and push a `v*` tag
3. let GitHub Actions build and upload NIF archives to the GitHub Release
4. let the publish job generate `checksum-Elixir.Optify.Native.exs`
5. publish the Hex package and docs after the release artifacts exist
