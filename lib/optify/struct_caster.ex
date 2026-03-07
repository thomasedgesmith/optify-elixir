defmodule Optify.StructCaster do
  @moduledoc false

  def cast(module, value) when is_atom(module) do
    cond do
      function_exported?(module, :from_optify, 1) ->
        {:ok, module.from_optify(value)}

      function_exported?(module, :__struct__, 0) and is_map(value) ->
        {:ok, to_struct(module, value)}

      true ->
        {:error,
         "#{inspect(module)} must define from_optify/1 or be a struct module for automatic casting"}
    end
  rescue
    e -> {:error, Exception.message(e)}
  end

  defp to_struct(module, map) do
    base = struct(module)

    updated =
      Enum.reduce(Map.from_struct(base), base, fn {key, _default}, acc ->
        case fetch_key(map, key) do
          {:ok, value} -> Map.put(acc, key, cast_field(Map.get(base, key), value))
          :error -> acc
        end
      end)

    updated
  end

  defp cast_field(%_{} = nested_struct, value) when is_map(value) do
    nested_module = nested_struct.__struct__
    to_struct(nested_module, value)
  end

  defp cast_field(%_{} = nested_struct, nil), do: nested_struct

  defp cast_field(_default, value), do: value

  defp fetch_key(map, key) when is_atom(key) do
    case Map.fetch(map, key) do
      {:ok, value} ->
        {:ok, value}

      :error ->
        Map.fetch(map, Atom.to_string(key))
    end
  end
end
