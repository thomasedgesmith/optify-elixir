defmodule Optify.GetOptionsPreferences do
  @moduledoc """
  Runtime preferences for resolving Optify options.

  This struct controls how feature selection and option resolution behave when
  calling APIs such as `Optify.get_options/2` and
  `Optify.get_filtered_feature_names/2`.

  You can pass either this struct or a plain map with matching keys.

  ## Fields

  - `:are_configurable_strings_enabled` enables configurable string evaluation.
  - `:constraints_json` provides constraint input as a JSON string.
  - `:overrides_json` provides override input as a JSON string.
  - `:skip_feature_name_conversion` keeps feature names as provided.
  """

  @enforce_keys []
  defstruct are_configurable_strings_enabled: false,
            constraints_json: nil,
            overrides_json: nil,
            skip_feature_name_conversion: false

  @type t :: %__MODULE__{
          are_configurable_strings_enabled: boolean(),
          constraints_json: String.t() | nil,
          overrides_json: String.t() | nil,
          skip_feature_name_conversion: boolean()
        }

  @type input_t :: t() | map()

  @doc """
  Normalize a preference struct or map into `%Optify.GetOptionsPreferences{}`.

  Map inputs may use either atom or string keys. The `:constraints` and
  `:overrides` keys may be maps or lists, which are encoded to JSON
  automatically.
  """
  @spec normalize(input_t()) :: t()
  def normalize(%__MODULE__{} = prefs), do: prefs

  def normalize(%{} = prefs) do
    %__MODULE__{
      are_configurable_strings_enabled:
        Map.get(prefs, :are_configurable_strings_enabled) ||
          Map.get(prefs, "are_configurable_strings_enabled", false),
      constraints_json:
        to_json_string(
          Map.get(prefs, :constraints_json) ||
            Map.get(prefs, "constraints_json") ||
            Map.get(prefs, :constraints) ||
            Map.get(prefs, "constraints")
        ),
      overrides_json:
        to_json_string(
          Map.get(prefs, :overrides_json) ||
            Map.get(prefs, "overrides_json") ||
            Map.get(prefs, :overrides) ||
            Map.get(prefs, "overrides")
        ),
      skip_feature_name_conversion:
        Map.get(prefs, :skip_feature_name_conversion) ||
          Map.get(prefs, "skip_feature_name_conversion", false)
    }
  end

  @doc """
  Convert preferences into the map shape expected by the Rust NIF layer.
  """
  @spec to_nif_map(input_t()) :: map()
  def to_nif_map(prefs) do
    prefs = normalize(prefs)

    %{
      are_configurable_strings_enabled: prefs.are_configurable_strings_enabled,
      constraints_json: prefs.constraints_json,
      overrides_json: prefs.overrides_json,
      skip_feature_name_conversion: prefs.skip_feature_name_conversion
    }
  end

  defp to_json_string(nil), do: nil
  defp to_json_string(value) when is_binary(value), do: value

  defp to_json_string(value) do
    Jason.encode!(value)
  end
end
