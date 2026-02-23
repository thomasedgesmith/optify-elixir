# Optify (Elixir / Phoenix)

Elixir client for [Optify](https://github.com/juharris/optify), powered by the upstream Rust crate via Rustler NIFs.

## Features

- Uses Rust `optify` crate directly for feature loading/merging logic
- Elixir API for building providers and fetching options
- Phoenix/Plug integration via `Optify.Plug`

## Installation

```elixir
def deps do
  [
    {:optify, git: "https://github.com/thomasedgesmith/optify-elixir"}
  ]
end
```

## Usage

Tuple + bang APIs are both available:

- `Optify.get_options/4` → `{:ok, value} | {:error, reason}`
- `Optify.get_options!/4` → `value` (raises on error)
- `Optify.get_options_json/4` / `Optify.get_options_json!/4`


```elixir
{:ok, provider} = Optify.build("config/optify")

options =
  Optify.get_options!(provider, "myConfig", ["feature_A", "feature_B"])

IO.inspect(options)
```

## Preferences

```elixir
prefs = %Optify.GetOptionsPreferences{
  are_configurable_strings_enabled: true,
  constraints_json: ~s({"clientId": 1234})
}

{:ok, options} = Optify.get_options(provider, "myConfig", ["feature_A"], prefs)
```

## Phoenix / Plug

Use `Optify.Plug` to assign options to `conn.assigns`:

```elixir
plug Optify.Plug,
  provider: provider,
  key: "myConfig",
  feature_names: fn conn -> conn.assigns[:features] || [] end,
  assign: :my_config
```

## Development

```bash
mix deps.get
mix format
mix test
```
