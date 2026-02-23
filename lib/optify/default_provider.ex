defmodule Optify.DefaultProvider do
  @moduledoc false

  use GenServer

  @tick_ms 1_000

  @type state :: %{
          provider: reference() | nil,
          directories: [String.t()],
          signature: integer() | nil,
          auto_reload: boolean(),
          poll_interval_ms: non_neg_integer()
        }

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def set(provider), do: GenServer.call(__MODULE__, {:set, provider})
  def get, do: GenServer.call(__MODULE__, :get)

  def get! do
    case get() do
      nil -> raise ArgumentError, "No default Optify provider is configured"
      provider -> provider
    end
  end

  def load_from_config! do
    GenServer.call(__MODULE__, :load_from_config)
  end

  @impl true
  def init(_) do
    provider_config = Application.get_env(:optify, :provider, [])
    directories = directories_from_config(provider_config)

    auto_load = Application.get_env(:optify, :auto_load_default_provider, false)
    auto_reload = Application.get_env(:optify, :auto_reload_default_provider, false)
    poll_interval_ms = Application.get_env(:optify, :provider_poll_interval_ms, @tick_ms)

    state = %{
      provider: nil,
      directories: directories,
      signature: nil,
      auto_reload: auto_reload,
      poll_interval_ms: poll_interval_ms
    }

    state =
      if auto_load or auto_reload do
        do_load(state)
      else
        state
      end

    if state.auto_reload, do: schedule_tick(state.poll_interval_ms)

    {:ok, state}
  end

  @impl true
  def handle_call({:set, provider}, _from, state) do
    {:reply, :ok, %{state | provider: provider}}
  end

  def handle_call(:get, _from, state) do
    {:reply, state.provider, state}
  end

  def handle_call(:load_from_config, _from, state) do
    state = do_load(state)
    {:reply, state.provider, state}
  end

  @impl true
  def handle_info(:tick, state) do
    next_state = maybe_reload(state)
    schedule_tick(next_state.poll_interval_ms)
    {:noreply, next_state}
  end

  defp schedule_tick(ms), do: Process.send_after(self(), :tick, ms)

  defp maybe_reload(%{directories: []} = state), do: state

  defp maybe_reload(state) do
    new_signature = signature(state.directories)

    if state.signature != nil and state.signature != new_signature do
      do_load(%{state | signature: new_signature})
    else
      %{state | signature: new_signature}
    end
  end

  defp do_load(state) do
    provider = Optify.build_from_config!()
    %{state | provider: provider, signature: signature(state.directories)}
  end

  defp directories_from_config(config) when is_list(config) do
    case {Keyword.get(config, :directory), Keyword.get(config, :directories)} do
      {directory, _} when is_binary(directory) -> [directory]
      {_, directories} when is_list(directories) -> directories
      _ -> []
    end
  end

  defp directories_from_config(config) when is_map(config) do
    case {Map.get(config, :directory) || Map.get(config, "directory"),
          Map.get(config, :directories) || Map.get(config, "directories")} do
      {directory, _} when is_binary(directory) -> [directory]
      {_, directories} when is_list(directories) -> directories
      _ -> []
    end
  end

  defp signature(directories) do
    directories
    |> Enum.flat_map(&list_files/1)
    |> Enum.map(fn path ->
      case File.stat(path) do
        {:ok, stat} -> {path, stat.size, stat.mtime}
        _ -> {path, :missing}
      end
    end)
    |> Enum.sort()
    |> :erlang.phash2()
  end

  defp list_files(directory) do
    directory
    |> Path.join("**/*")
    |> Path.wildcard(match_dot: true)
    |> Enum.filter(&File.regular?/1)
  end
end
