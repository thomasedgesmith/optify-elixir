defmodule Optify.GetOptionsPreferences do
  @moduledoc """
  Runtime preferences for building options.
  """

  @enforce_keys []
  defstruct are_configurable_strings_enabled: false,
            constraints_json: nil,
            skip_feature_name_conversion: false

  @type t :: %__MODULE__{
          are_configurable_strings_enabled: boolean(),
          constraints_json: String.t() | nil,
          skip_feature_name_conversion: boolean()
        }

  @spec to_nif_map(t()) :: map()
  def to_nif_map(%__MODULE__{} = prefs) do
    %{
      are_configurable_strings_enabled: prefs.are_configurable_strings_enabled,
      constraints_json: prefs.constraints_json,
      skip_feature_name_conversion: prefs.skip_feature_name_conversion
    }
  end
end
