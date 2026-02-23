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
      Enum.reduce(Map.keys(base), base, fn key, acc ->
        string_key = Atom.to_string(key)

        case Map.fetch(map, string_key) do
          {:ok, value} -> Map.put(acc, key, cast_field(Map.get(base, key), value))
          :error -> acc
        end
      end)

    struct(module, updated)
  end

  defp cast_field(%_{} = nested_struct, value) when is_map(value) do
    nested_module = nested_struct.__struct__
    to_struct(nested_module, value)
  end

  defp cast_field(_default, value), do: value
end
