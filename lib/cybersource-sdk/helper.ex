defmodule CyberSourceSDK.Helper do
  @doc """
  Convert a Map that have a list of strings
  """
  def convert_map_to_key_atom(string_key_map) when is_map(string_key_map) do
    for {key, val} <- string_key_map, into: %{}, do: {String.to_atom(key), convert_map_to_key_atom(val)}
  end

  def convert_map_to_key_atom(list_maps) when is_list(list_maps) do
    Enum.map(list_maps, fn (map) -> convert_map_to_key_atom(map) end)
  end

  def convert_map_to_key_atom(string_key_map) when is_number(string_key_map) or is_nil(string_key_map) do
    string_key_map
  end

  def convert_map_to_key_atom(value) do
    if String.valid?(value) do
      value
    else
      Kernel.inspect(value) # Convert to string
    end
  end
end
