defmodule Optify do
  @moduledoc """
  Optify high-level API.

  Public API (stable):
  - `get_options/2`
  - `get_options/4`
  - `get_options!/2`
  - `get_options!/4`
  """

  alias Optify.DefaultProvider
  alias Optify.GetOptionsPreferences
  alias Optify.Native
  alias Optify.StructCaster

  @type provider :: reference()
  @type build_config_input :: keyword() | map() | nil

  @doc false
  @spec build(String.t()) :: {:ok, provider()} | {:error, String.t()}
  def build(directory), do: Native.build_provider(directory)

  @doc false
  @spec build!(String.t()) :: provider()
  def build!(directory) do
    case build(directory) do
      {:ok, provider} -> provider
      {:error, reason} -> raise ArgumentError, "Optify.build!/1 failed: #{reason}"
    end
  end

  @doc false
  @spec build_with_schema(String.t(), String.t()) :: {:ok, provider()} | {:error, String.t()}
  def build_with_schema(directory, schema_path),
    do: Native.build_provider_with_schema(directory, schema_path)

  @doc false
  @spec build_with_schema!(String.t(), String.t()) :: provider()
  def build_with_schema!(directory, schema_path) do
    case build_with_schema(directory, schema_path) do
      {:ok, provider} -> provider
      {:error, reason} -> raise ArgumentError, "Optify.build_with_schema!/2 failed: #{reason}"
    end
  end

  @doc false
  @spec build_from_directories([String.t()]) :: {:ok, provider()} | {:error, String.t()}
  def build_from_directories(directories), do: Native.build_provider_from_directories(directories)

  @doc false
  @spec build_from_directories!([String.t()]) :: provider()
  def build_from_directories!(directories) do
    case build_from_directories(directories) do
      {:ok, provider} ->
        provider

      {:error, reason} ->
        raise ArgumentError, "Optify.build_from_directories!/1 failed: #{reason}"
    end
  end

  @doc false
  @spec build_from_directories_with_schema([String.t()], String.t()) ::
          {:ok, provider()} | {:error, String.t()}
  def build_from_directories_with_schema(directories, schema_path),
    do: Native.build_provider_from_directories_with_schema(directories, schema_path)

  @doc false
  @spec build_from_directories_with_schema!([String.t()], String.t()) :: provider()
  def build_from_directories_with_schema!(directories, schema_path) do
    case build_from_directories_with_schema(directories, schema_path) do
      {:ok, provider} ->
        provider

      {:error, reason} ->
        raise ArgumentError,
              "Optify.build_from_directories_with_schema!/2 failed: #{reason}"
    end
  end

  @doc false
  @spec build_from_config(build_config_input()) :: {:ok, provider()} | {:error, String.t()}
  def build_from_config(config \\ nil)

  def build_from_config(nil), do: build_from_config(Application.get_env(:optify, :provider, []))

  def build_from_config(config) when is_list(config) or is_map(config) do
    case extract_build_config(config) do
      {:directory, directory, nil} ->
        build(directory)

      {:directory, directory, schema_path} ->
        build_with_schema(directory, schema_path)

      {:directories, directories, nil} ->
        build_from_directories(directories)

      {:directories, directories, schema_path} ->
        build_from_directories_with_schema(directories, schema_path)

      :error ->
        {:error, missing_provider_config_error()}
    end
  end

  @doc false
  @spec build_from_config!(build_config_input()) :: provider()
  def build_from_config!(config \\ nil) do
    case build_from_config(config) do
      {:ok, provider} -> provider
      {:error, reason} -> raise ArgumentError, "Optify.build_from_config!/1 failed: #{reason}"
    end
  end

  @doc false
  @spec set_default_provider(provider()) :: :ok
  def set_default_provider(provider), do: DefaultProvider.set(provider)

  @doc false
  @spec default_provider() :: provider() | nil
  def default_provider, do: DefaultProvider.get()

  @doc false
  @spec default_provider!() :: provider()
  def default_provider!, do: DefaultProvider.get!()

  @doc false
  @spec load_default_provider!(keyword() | map() | nil) :: provider()
  def load_default_provider!(config \\ nil) do
    provider = build_from_config!(config)
    set_default_provider(provider)
    provider
  end

  @doc false
  @spec features() :: [String.t()]
  def features, do: get_features()

  @doc false
  @spec features(provider()) :: [String.t()]
  def features(provider), do: get_features(provider)

  @doc false
  @spec get_features() :: [String.t()]
  def get_features, do: get_features(default_provider!())

  @doc false
  @spec get_features(provider()) :: [String.t()]
  def get_features(provider), do: Native.features(provider)

  @doc false
  @spec get_aliases() :: [String.t()]
  def get_aliases, do: get_aliases(default_provider!())

  @doc false
  @spec get_aliases(provider()) :: [String.t()]
  def get_aliases(provider), do: Native.get_aliases(provider)

  @doc false
  @spec get_features_and_aliases() :: [String.t()]
  def get_features_and_aliases, do: get_features_and_aliases(default_provider!())

  @doc false
  @spec get_features_and_aliases(provider()) :: [String.t()]
  def get_features_and_aliases(provider), do: Native.get_features_and_aliases(provider)

  @doc false
  @spec get_canonical_feature_name(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def get_canonical_feature_name(feature_name),
    do: get_canonical_feature_name(default_provider!(), feature_name)

  @doc false
  @spec get_canonical_feature_name(provider(), String.t()) ::
          {:ok, String.t()} | {:error, String.t()}
  def get_canonical_feature_name(provider, feature_name),
    do: Native.get_canonical_feature_name(provider, feature_name)

  @doc false
  @spec get_canonical_feature_name!(String.t()) :: String.t()
  def get_canonical_feature_name!(feature_name) do
    case get_canonical_feature_name(feature_name) do
      {:ok, canonical_feature_name} ->
        canonical_feature_name

      {:error, reason} ->
        raise ArgumentError, "Optify.get_canonical_feature_name!/1 failed: #{reason}"
    end
  end

  @doc false
  @spec get_canonical_feature_names([String.t()]) :: {:ok, [String.t()]} | {:error, String.t()}
  def get_canonical_feature_names(feature_names),
    do: get_canonical_feature_names(default_provider!(), feature_names)

  @doc false
  @spec get_canonical_feature_names(provider(), [String.t()]) ::
          {:ok, [String.t()]} | {:error, String.t()}
  def get_canonical_feature_names(provider, feature_names),
    do: Native.get_canonical_feature_names(provider, feature_names)

  @doc false
  @spec get_canonical_feature_names!([String.t()]) :: [String.t()]
  def get_canonical_feature_names!(feature_names) do
    case get_canonical_feature_names(feature_names) do
      {:ok, canonical_feature_names} ->
        canonical_feature_names

      {:error, reason} ->
        raise ArgumentError, "Optify.get_canonical_feature_names!/1 failed: #{reason}"
    end
  end

  @doc false
  @spec get_feature_metadata(String.t()) :: map() | nil
  def get_feature_metadata(canonical_feature_name),
    do: get_feature_metadata(default_provider!(), canonical_feature_name)

  @doc false
  @spec get_feature_metadata(provider(), String.t()) :: map() | nil
  def get_feature_metadata(provider, canonical_feature_name) do
    case Native.get_feature_metadata_json(provider, canonical_feature_name) do
      nil -> nil
      json -> decode_json!(json)
    end
  end

  @doc false
  @spec get_features_with_metadata() :: map()
  def get_features_with_metadata, do: get_features_with_metadata(default_provider!())

  @doc false
  @spec get_features_with_metadata(provider()) :: map()
  def get_features_with_metadata(provider) do
    provider
    |> Native.get_features_with_metadata_json()
    |> decode_json!()
  end

  @doc false
  @spec get_filtered_feature_names([String.t()]) :: {:ok, [String.t()]} | {:error, String.t()}
  def get_filtered_feature_names(feature_names),
    do: get_filtered_feature_names(feature_names, %GetOptionsPreferences{})

  @doc false
  @spec get_filtered_feature_names([String.t()], GetOptionsPreferences.input_t()) ::
          {:ok, [String.t()]} | {:error, String.t()}
  def get_filtered_feature_names(feature_names, preferences) when is_list(feature_names) do
    get_filtered_feature_names(default_provider!(), feature_names, preferences)
  end

  @doc false
  @spec get_filtered_feature_names(provider(), [String.t()], GetOptionsPreferences.input_t()) ::
          {:ok, [String.t()]} | {:error, String.t()}
  def get_filtered_feature_names(provider, feature_names, preferences) do
    Native.get_filtered_feature_names(
      provider,
      feature_names,
      GetOptionsPreferences.to_nif_map(preferences)
    )
  end

  @doc false
  @spec get_filtered_feature_names!([String.t()]) :: [String.t()]
  def get_filtered_feature_names!(feature_names),
    do: get_filtered_feature_names!(feature_names, %GetOptionsPreferences{})

  @doc false
  @spec get_filtered_feature_names!([String.t()], GetOptionsPreferences.input_t()) ::
          [String.t()]
  def get_filtered_feature_names!(feature_names, preferences) when is_list(feature_names) do
    case get_filtered_feature_names(feature_names, preferences) do
      {:ok, resolved_feature_names} ->
        resolved_feature_names

      {:error, reason} ->
        raise ArgumentError, "Optify.get_filtered_feature_names!/2 failed: #{reason}"
    end
  end

  @doc false
  @spec get_filtered_feature_names!(provider(), [String.t()], GetOptionsPreferences.input_t()) ::
          [String.t()]
  def get_filtered_feature_names!(provider, feature_names, preferences) do
    case get_filtered_feature_names(provider, feature_names, preferences) do
      {:ok, resolved_feature_names} ->
        resolved_feature_names

      {:error, reason} ->
        raise ArgumentError, "Optify.get_filtered_feature_names!/3 failed: #{reason}"
    end
  end

  @doc false
  @spec has_conditions(String.t()) :: boolean()
  def has_conditions(canonical_feature_name),
    do: has_conditions(default_provider!(), canonical_feature_name)

  @doc false
  @spec has_conditions(provider(), String.t()) :: boolean()
  def has_conditions(provider, canonical_feature_name),
    do: Native.has_conditions(provider, canonical_feature_name)

  @doc """
  Get merged options using the default provider.

  Returns atom-keyed maps by default so dot access works (e.g. `options.flow`).
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
  Bang variant of `get_options/2`.
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
  Get options for one top-level key from the given provider.
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
  Bang variant of `get_options/4`.
  """
  @spec get_options!(provider(), String.t(), [String.t()], GetOptionsPreferences.input_t()) ::
          map() | list() | String.t() | number() | boolean() | nil
  def get_options!(provider, key, feature_names, preferences \\ %GetOptionsPreferences{}) do
    case get_options(provider, key, feature_names, preferences) do
      {:ok, options} -> options
      {:error, reason} -> raise ArgumentError, "Optify.get_options!/4 failed: #{reason}"
    end
  end

  @doc false
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

  @doc false
  @spec get_all_options!(provider(), [String.t()], GetOptionsPreferences.input_t()) ::
          map() | list() | String.t() | number() | boolean() | nil
  def get_all_options!(provider, feature_names, preferences \\ %GetOptionsPreferences{}) do
    case get_all_options(provider, feature_names, preferences) do
      {:ok, options} -> options
      {:error, reason} -> raise ArgumentError, "Optify.get_all_options!/3 failed: #{reason}"
    end
  end

  @doc false
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

  @doc false
  @spec get_all_options_json(provider(), [String.t()], GetOptionsPreferences.input_t()) ::
          {:ok, String.t()} | {:error, String.t()}
  def get_all_options_json(provider, feature_names, preferences \\ %GetOptionsPreferences{}) do
    Native.get_all_options_json_with_preferences(
      provider,
      feature_names,
      GetOptionsPreferences.to_nif_map(preferences)
    )
  end

  @doc false
  @spec get_options_json!(provider(), String.t(), [String.t()], GetOptionsPreferences.input_t()) ::
          String.t()
  def get_options_json!(provider, key, feature_names, preferences \\ %GetOptionsPreferences{}) do
    case get_options_json(provider, key, feature_names, preferences) do
      {:ok, json} -> json
      {:error, reason} -> raise ArgumentError, "Optify.get_options_json!/4 failed: #{reason}"
    end
  end

  @doc false
  @spec get_all_options_json!(provider(), [String.t()], GetOptionsPreferences.input_t()) ::
          String.t()
  def get_all_options_json!(provider, feature_names, preferences \\ %GetOptionsPreferences{}) do
    case get_all_options_json(provider, feature_names, preferences) do
      {:ok, json} -> json
      {:error, reason} -> raise ArgumentError, "Optify.get_all_options_json!/3 failed: #{reason}"
    end
  end

  defp cast_output(value, nil), do: {:ok, value}
  defp cast_output(value, module) when is_atom(module), do: StructCaster.cast(module, value)

  defp transform_keys(value, :strings), do: value

  defp transform_keys(value, :atoms) when is_map(value) do
    value
    |> Enum.map(fn {k, v} -> {to_atom_key(k), transform_keys(v, :atoms)} end)
    |> Map.new()
  end

  defp transform_keys(value, :atoms) when is_list(value),
    do: Enum.map(value, &transform_keys(&1, :atoms))

  defp transform_keys(value, _), do: value

  defp to_atom_key(key) when is_atom(key), do: key
  defp to_atom_key(key) when is_binary(key), do: String.to_atom(key)
  defp to_atom_key(key), do: key

  defp extract_build_config(config) when is_list(config) do
    schema_path = Keyword.get(config, :schema_path) || Keyword.get(config, :schema)

    cond do
      directory = Keyword.get(config, :directory) ->
        {:directory, directory, schema_path}

      directories = Keyword.get(config, :directories) ->
        {:directories, directories, schema_path}

      true ->
        :error
    end
  end

  defp extract_build_config(config) when is_map(config) do
    schema_path =
      Map.get(config, :schema_path) ||
        Map.get(config, "schema_path") ||
        Map.get(config, :schema) ||
        Map.get(config, "schema")

    cond do
      directory = Map.get(config, :directory) || Map.get(config, "directory") ->
        {:directory, directory, schema_path}

      directories = Map.get(config, :directories) || Map.get(config, "directories") ->
        {:directories, directories, schema_path}

      true ->
        :error
    end
  end

  defp missing_provider_config_error do
    "Missing provider config. Set :directory or :directories in config :optify, :provider"
  end

  defp decode_json(json) do
    case Jason.decode(json) do
      {:ok, decoded} -> {:ok, decoded}
      {:error, %Jason.DecodeError{} = err} -> {:error, Exception.message(err)}
    end
  end

  defp decode_json!(json) do
    case decode_json(json) do
      {:ok, decoded} -> decoded
      {:error, reason} -> raise ArgumentError, "Optify JSON decode failed: #{reason}"
    end
  end
end
