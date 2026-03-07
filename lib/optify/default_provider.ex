defmodule Optify.DefaultProvider do
  @moduledoc false

  use GenServer

  alias Optify.OptionShapeCache

  @type state :: %{
          provider: reference() | nil,
          directories: [String.t()],
          watcher_pid: pid() | nil,
          auto_reload: boolean()
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

    auto_load = Application.get_env(:optify, :auto_load_default_provider, true)
    auto_reload = Application.get_env(:optify, :auto_reload_default_provider, false)

    state = %{
      provider: nil,
      directories: directories,
      watcher_pid: nil,
      auto_reload: auto_reload
    }

    state =
      if (auto_load or auto_reload) and directories != [] do
        do_load(state)
      else
        state
      end

    {:ok, maybe_start_watcher(state)}
  end

  @impl true
  def handle_call({:set, provider}, _from, state) do
    OptionShapeCache.delete(state.provider)
    warm_option_shape(provider)

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
  def handle_info(
        {:file_event, watcher_pid, {_path, events}},
        %{watcher_pid: watcher_pid} = state
      ) do
    # FileSystem adapters differ slightly, so match broadly for change/create/remove.
    if Enum.any?(events, &(&1 in [:modified, :created, :removed])) do
      {:noreply, do_load(state)}
    else
      {:noreply, state}
    end
  end

  def handle_info({:file_event, _watcher_pid, :stop}, state), do: {:noreply, state}
  def handle_info(_msg, state), do: {:noreply, state}

  @impl true
  def terminate(_reason, %{watcher_pid: nil}), do: :ok

  def terminate(_reason, %{watcher_pid: watcher_pid}) do
    Process.exit(watcher_pid, :normal)
    :ok
  end

  defp maybe_start_watcher(%{auto_reload: false} = state), do: state
  defp maybe_start_watcher(%{directories: []} = state), do: state

  defp maybe_start_watcher(state) do
    {:ok, watcher_pid} = FileSystem.start_link(dirs: state.directories)
    FileSystem.subscribe(watcher_pid)
    %{state | watcher_pid: watcher_pid}
  end

  defp do_load(state) do
    provider = Optify.build_from_config!()
    OptionShapeCache.delete(state.provider)
    warm_option_shape(provider)
    %{state | provider: provider}
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

  defp warm_option_shape(nil), do: :ok
  defp warm_option_shape(provider), do: Optify.warm_option_shape(provider)
end
