defmodule Optify.Plug do
  @moduledoc """
  Plug for Phoenix/Plug apps to load Optify options and assign them to `conn.assigns`.
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

    [
      provider: provider,
      key: key,
      assign: assign,
      feature_names: feature_names,
      preferences: preferences
    ]
  end

  @impl Plug
  def call(conn, opts) do
    features = resolve(conn, opts[:feature_names], [])
    preferences = resolve(conn, opts[:preferences], %GetOptionsPreferences{})

    case Optify.get_options(opts[:provider], opts[:key], features, preferences) do
      {:ok, options} -> assign(conn, opts[:assign], options)
      {:error, reason} -> raise "Optify.Plug failed to fetch options: #{reason}"
    end
  end

  defp resolve(conn, value, _default) when is_function(value, 1), do: value.(conn)
  defp resolve(_conn, nil, default), do: default
  defp resolve(_conn, value, _default), do: value
end
