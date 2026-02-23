defmodule Optify.Plug do
  @moduledoc """
  Plug for Phoenix/Plug apps to load Optify options and assign them to `conn.assigns`.

  Supports controller/request-provided option maps so you can pass per-request
  feature names and preferences.
  """

  @behaviour Plug

  import Plug.Conn

  alias Optify.GetOptionsPreferences

  @impl Plug
  def init(opts) do
    provider = Keyword.fetch!(opts, :provider)
    key = Keyword.fetch!(opts, :key)

    assign = Keyword.get(opts, :assign, :optify_options)
    feature_names = Keyword.get(opts, :feature_names, [])
    preferences = Keyword.get(opts, :preferences, %GetOptionsPreferences{})
    options = Keyword.get(opts, :options, %{})
    options_assign = Keyword.get(opts, :options_assign)

    [
      provider: provider,
      key: key,
      assign: assign,
      feature_names: feature_names,
      preferences: preferences,
      options: options,
      options_assign: options_assign
    ]
  end

  @impl Plug
  def call(conn, opts) do
    controller_options =
      if assign_key = opts[:options_assign] do
        Map.get(conn.assigns, assign_key, %{})
      else
        %{}
      end

    resolved_options =
      conn
      |> resolve(opts[:options], %{})
      |> Map.merge(controller_options)

    features =
      resolved_options
      |> Map.get(:feature_names, Map.get(resolved_options, "feature_names"))
      |> default_to(resolve(conn, opts[:feature_names], []))

    preferences =
      resolved_options
      |> Map.get(:preferences, Map.get(resolved_options, "preferences"))
      |> default_to(resolve(conn, opts[:preferences], %GetOptionsPreferences{}))
      |> GetOptionsPreferences.normalize()

    case Optify.get_options(opts[:provider], opts[:key], features, preferences) do
      {:ok, options_value} -> assign(conn, opts[:assign], options_value)
      {:error, reason} -> raise "Optify.Plug failed to fetch options: #{reason}"
    end
  end

  defp resolve(conn, value, _default) when is_function(value, 1), do: value.(conn)
  defp resolve(_conn, nil, default), do: default
  defp resolve(_conn, value, _default), do: value

  defp default_to(nil, fallback), do: fallback
  defp default_to(value, _fallback), do: value
end
