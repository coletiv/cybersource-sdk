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

  @doc """
  Decode base64 string to JSON structure
  """
  def json_from_base64(base64_string) do
    case Base.decode64(base64_string) do
      {:ok, json} ->
        case Poison.Parser.parse(json) do
          {:ok, json} -> {:ok, convert_map_to_key_atom(json)}
          {:error, reason} -> {:error, reason}
        end
      _ -> {:error, :bad_base64_encoding}
    end
  end
end
