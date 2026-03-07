defmodule Optify.OptionShapeCache do
  @moduledoc false

  @table :optify_option_shape_cache

  def fetch(provider, loader) when is_function(loader, 0) do
    table = ensure_table()

    case :ets.lookup(table, provider) do
      [{^provider, shape}] ->
        shape

      [] ->
        shape = loader.()
        true = :ets.insert(table, {provider, shape})
        shape
    end
  end

  def delete(nil), do: :ok

  def delete(provider) do
    case :ets.whereis(@table) do
      :undefined ->
        :ok

      table ->
        :ets.delete(table, provider)
        :ok
    end
  end

  defp ensure_table do
    case :ets.whereis(@table) do
      :undefined ->
        try do
          :ets.new(@table, [
            :named_table,
            :public,
            read_concurrency: true,
            write_concurrency: true
          ])
        rescue
          ArgumentError -> :ets.whereis(@table)
        end

      table ->
        table
    end
  end
end
