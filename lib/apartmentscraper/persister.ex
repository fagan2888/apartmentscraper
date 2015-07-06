defmodule ApartmentScraper.Persister do
  alias Calendar.DateTime
  # TODO: implement this as a separate server process.
  # In the meantime, use this as a namespace for writer
  # functions

  @file_path "apartments.json"

  defp decode_rent_entry(entry) do
      [timestamp, rent] = entry
      [DateTime.Parse.unix!(timestamp), rent]
  end

  defp encode_rent_entry(entry) do
    [datetime, rent] = entry
    [DateTime.Format.unix(datetime), rent]
  end

  defp reformat_history_map(map, entry_formatter) do
    handle_unit_history = fn(entry, map) ->
      {unit, raw_history} = entry
      Map.put(map, unit, Enum.map(raw_history, entry_formatter))
    end
    Enum.reduce(map, %{}, handle_unit_history)
  end

  defp add_rent(apt, map) do
    key = apt.unit
    updated_map = Dict.put_new(map, apt.unit, [])
    latest_rent = [DateTime.now_utc, apt.rent]
    rent_history = Dict.get(updated_map, key)
    Dict.put(updated_map, key, [latest_rent] ++ rent_history)
  end

  @doc """
  Write timestamps and rent values to a JSON dict, keyed
  by unit name.
  """
  def save_rents(apartments, history) do
    rent_data = Enum.reduce(apartments, history, &add_rent/2)
    formatted_rent_data = reformat_history_map rent_data, &encode_rent_entry/1
    case JSX.encode(formatted_rent_data) do
      {:ok, encoded} -> File.write! @file_path, encoded
      {:error, reason} -> IO.puts :stderr, "Could not encode rent data: #{reason}"
    end
  end

  @doc """
  Load existing JSON data into an in-memory data structure.
  """
  def load_rents do
    case File.read(@file_path) do
      {:ok, contents} ->
        {:ok, decoded} = JSX.decode(contents)
        reformat_history_map decoded, &decode_rent_entry/1
      {:error, reason} ->
        IO.puts :stderr, "Could not load rent file: #{reason}. Overwriting..."
        %{}
    end
  end
end
