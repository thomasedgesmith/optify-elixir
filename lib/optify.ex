defmodule Optify do
  @moduledoc """
  Elixir client for Optify backed by the upstream Rust crate.

  This module exposes the main provider APIs and returns Elixir maps by default.
  """

  alias Optify.DefaultProvider
  alias Optify.GetOptionsPreferences
  alias Optify.Native
  alias Optify.StructCaster

  @type provider :: reference()

  @doc """
  Build a provider from one config directory.
  """
  @spec build(String.t()) :: {:ok, provider()} | {:error, String.t()}
  def build(directory), do: Native.build_provider(directory)

  @doc """
  Same as `build/1` but returns the provider directly and raises on failure.
  """
  @spec build!(String.t()) :: provider()
  def build!(directory) do
    case build(directory) do
      {:ok, provider} -> provider
      {:error, reason} -> raise ArgumentError, "Optify.build!/1 failed: #{reason}"
    end
  end

  @doc """
  Build a provider from multiple config directories.
  """
  @spec build_from_directories([String.t()]) :: {:ok, provider()} | {:error, String.t()}
  def build_from_directories(directories), do: Native.build_provider_from_directories(directories)

  @doc """
  Same as `build_from_directories/1` but returns provider directly and raises on failure.
  """
  @spec build_from_directories!([String.t()]) :: provider()
  def build_from_directories!(directories) do
    case build_from_directories(directories) do
      {:ok, provider} ->
        provider

      {:error, reason} ->
        raise ArgumentError, "Optify.build_from_directories!/1 failed: #{reason}"
    end
  end

  @doc """
  Build provider from application config.

  Reads from `config :optify, :provider, ...` and supports:
  - `directory: "path/to/configs"`
  - `directories: ["path/a", "path/b"]`
  """
  @spec build_from_config(keyword() | map() | nil) :: {:ok, provider()} | {:error, String.t()}
  def build_from_config(config \\ nil)

  def build_from_config(nil) do
    build_from_config(Application.get_env(:optify, :provider, []))
  end

  def build_from_config(config) when is_list(config) do
    cond do
      directory = Keyword.get(config, :directory) ->
        build(directory)

      directories = Keyword.get(config, :directories) ->
        build_from_directories(directories)

      true ->
        {:error,
         "Missing provider config. Set :directory or :directories in config :optify, :provider"}
    end
  end

  def build_from_config(config) when is_map(config) do
    cond do
      directory = Map.get(config, :directory) || Map.get(config, "directory") ->
        build(directory)

      directories = Map.get(config, :directories) || Map.get(config, "directories") ->
        build_from_directories(directories)

      true ->
        {:error,
         "Missing provider config. Set :directory or :directories in config :optify, :provider"}
    end
  end

  @doc """
  Same as `build_from_config/1` but raises on failure.
  """
  @spec build_from_config!(keyword() | map() | nil) :: provider()
  def build_from_config!(config \\ nil) do
    case build_from_config(config) do
      {:ok, provider} -> provider
      {:error, reason} -> raise ArgumentError, "Optify.build_from_config!/1 failed: #{reason}"
    end
  end

  @doc """
  Set the default provider used by convenience APIs like `get_options/1`.
  """
  @spec set_default_provider(provider()) :: :ok
  def set_default_provider(provider), do: DefaultProvider.set(provider)

  @doc """
  Get the default provider.
  """
  @spec default_provider() :: provider() | nil
  def default_provider, do: DefaultProvider.get()

  @doc """
  Get the default provider and raise if none is configured.
  """
  @spec default_provider!() :: provider()
  def default_provider!, do: DefaultProvider.get!()

  @doc """
  Build a provider from config and set it as default.
  """
  @spec load_default_provider!(keyword() | map() | nil) :: provider()
  def load_default_provider!(config \\ nil) do
    provider = build_from_config!(config)
    set_default_provider(provider)
    provider
  end

  @spec features(provider()) :: [String.t()]
  def features(provider), do: Native.features(provider)

  @spec get_canonical_feature_name(provider(), String.t()) ::
          {:ok, String.t()} | {:error, String.t()}
  def get_canonical_feature_name(provider, feature_name),
    do: Native.get_canonical_feature_name(provider, feature_name)

  @spec get_canonical_feature_names(provider(), [String.t()]) ::
          {:ok, [String.t()]} | {:error, String.t()}
  def get_canonical_feature_names(provider, feature_names),
    do: Native.get_canonical_feature_names(provider, feature_names)

  @doc """
  Convenience API: get full merged options using the default provider.

  Example:
      options = Optify.get_options!(["feature_a"])
      options.flow

  By default keys are atomized to support dot access.
  """
  @spec get_options([String.t()], keyword()) ::
          {:ok, map() | list() | String.t() | number() | boolean() | nil} | {:error, String.t()}
  def get_options(feature_names, opts \\ []) when is_list(feature_names) and is_list(opts) do
    provider = Keyword.get(opts, :provider, default_provider!())
    preferences = Keyword.get(opts, :preferences, %GetOptionsPreferences{})

    key_mode = Keyword.get(opts, :keys, :atoms)
    as_module = Keyword.get(opts, :as)

    with {:ok, options} <- get_all_options(provider, feature_names, preferences) do
      options
      |> transform_keys(key_mode)
      |> cast_output(as_module)
    end
  end

  @doc """
  Bang variant of `get_options/2` convenience API.
  """
  @spec get_options!([String.t()], keyword()) ::
          map() | list() | String.t() | number() | boolean() | nil
  def get_options!(feature_names, opts \\ []) when is_list(feature_names) and is_list(opts) do
    case get_options(feature_names, opts) do
      {:ok, options} -> options
      {:error, reason} -> raise ArgumentError, "Optify.get_options!/2 failed: #{reason}"
    end
  end

  @doc """
  Get options for one key and decode the returned JSON into Elixir terms.
  """
  @spec get_options(provider(), String.t(), [String.t()], GetOptionsPreferences.input_t()) ::
          {:ok, map() | list() | String.t() | number() | boolean() | nil} | {:error, String.t()}
  def get_options(provider, key, feature_names, preferences \\ %GetOptionsPreferences{}) do
    with {:ok, json} <-
           Native.get_options_json_with_preferences(
             provider,
             key,
             feature_names,
             GetOptionsPreferences.to_nif_map(preferences)
           ) do
      decode_json(json)
    end
  end

  @doc """
  Get all merged options and decode JSON into Elixir terms.
  """
  @spec get_all_options(provider(), [String.t()], GetOptionsPreferences.input_t()) ::
          {:ok, map() | list() | String.t() | number() | boolean() | nil} | {:error, String.t()}
  def get_all_options(provider, feature_names, preferences \\ %GetOptionsPreferences{}) do
    with {:ok, json} <-
           Native.get_all_options_json_with_preferences(
             provider,
             feature_names,
             GetOptionsPreferences.to_nif_map(preferences)
           ) do
      decode_json(json)
    end
  end

  @doc """
  Same as `get_options/4` but returns the value directly and raises on failure.
  """
  @spec get_options!(provider(), String.t(), [String.t()], GetOptionsPreferences.input_t()) ::
          map() | list() | String.t() | number() | boolean() | nil
  def get_options!(provider, key, feature_names, preferences \\ %GetOptionsPreferences{}) do
    case get_options(provider, key, feature_names, preferences) do
      {:ok, options} -> options
      {:error, reason} -> raise ArgumentError, "Optify.get_options!/4 failed: #{reason}"
    end
  end

  @doc """
  Same as `get_all_options/3` but returns value directly and raises on failure.
  """
  @spec get_all_options!(provider(), [String.t()], GetOptionsPreferences.input_t()) ::
          map() | list() | String.t() | number() | boolean() | nil
  def get_all_options!(provider, feature_names, preferences \\ %GetOptionsPreferences{}) do
    case get_all_options(provider, feature_names, preferences) do
      {:ok, options} -> options
      {:error, reason} -> raise ArgumentError, "Optify.get_all_options!/3 failed: #{reason}"
    end
  end

  @doc """
  Get options for one key as raw JSON.
  """
  @spec get_options_json(provider(), String.t(), [String.t()], GetOptionsPreferences.input_t()) ::
          {:ok, String.t()} | {:error, String.t()}
  def get_options_json(provider, key, feature_names, preferences \\ %GetOptionsPreferences{}) do
    Native.get_options_json_with_preferences(
      provider,
      key,
      feature_names,
      GetOptionsPreferences.to_nif_map(preferences)
    )
  end

  @doc """
  Get all merged options as raw JSON.
  """
  @spec get_all_options_json(provider(), [String.t()], GetOptionsPreferences.input_t()) ::
          {:ok, String.t()} | {:error, String.t()}
  def get_all_options_json(provider, feature_names, preferences \\ %GetOptionsPreferences{}) do
    Native.get_all_options_json_with_preferences(
      provider,
      feature_names,
      GetOptionsPreferences.to_nif_map(preferences)
    )
  end

  @doc """
  Same as `get_options_json/4` but returns JSON directly and raises on failure.
  """
  @spec get_options_json!(provider(), String.t(), [String.t()], GetOptionsPreferences.input_t()) ::
          String.t()
  def get_options_json!(provider, key, feature_names, preferences \\ %GetOptionsPreferences{}) do
    case get_options_json(provider, key, feature_names, preferences) do
      {:ok, json} -> json
      {:error, reason} -> raise ArgumentError, "Optify.get_options_json!/4 failed: #{reason}"
    end
  end

  @doc """
  Same as `get_all_options_json/3` but returns JSON directly and raises on failure.
  """
  @spec get_all_options_json!(provider(), [String.t()], GetOptionsPreferences.input_t()) ::
          String.t()
  def get_all_options_json!(provider, feature_names, preferences \\ %GetOptionsPreferences{}) do
    case get_all_options_json(provider, feature_names, preferences) do
      {:ok, json} -> json
      {:error, reason} -> raise ArgumentError, "Optify.get_all_options_json!/3 failed: #{reason}"
    end
  end

  defp cast_output(value, nil), do: {:ok, value}

  defp cast_output(value, module) when is_atom(module) do
    StructCaster.cast(module, value)
  end

  defp transform_keys(value, :strings), do: value

  defp transform_keys(value, :atoms) when is_map(value) do
    value
    |> Enum.map(fn {k, v} -> {to_atom_key(k), transform_keys(v, :atoms)} end)
    |> Map.new()
  end

  defp transform_keys(value, :atoms) when is_list(value) do
    Enum.map(value, &transform_keys(&1, :atoms))
  end

  defp transform_keys(value, _), do: value

  defp to_atom_key(key) when is_atom(key), do: key
  defp to_atom_key(key) when is_binary(key), do: String.to_atom(key)
  defp to_atom_key(key), do: key

  defp decode_json(json) do
    case Jason.decode(json) do
      {:ok, decoded} -> {:ok, decoded}
      {:error, %Jason.DecodeError{} = err} -> {:error, Exception.message(err)}
    end
  end
end
