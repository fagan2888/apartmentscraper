defmodule ApartmentScraper do
  alias ApartmentScraper.Fetcher
  alias ApartmentScraper.Parser
  alias ApartmentScraper.Persister

  def run do
    IO.puts "Loading apartments (Capitol Yards)..."
    raw_html = Fetcher.CapitolYards.get_html
    IO.puts "Parsing..."
    apartments = Parser.CapitolYards.parse_html raw_html
    IO.puts "Notifying..."
    history = Persister.load_rents
    reasons_to_notify = notify_reasons(apartments, history)
    if reasons_to_notify do
      notify reasons_to_notify, apartments
    end
    IO.puts "Saving..."
    Persister.save_rents apartments, history
  end

  # Pull out reasons to notify for each unit -- if we end up with no reasons
  # to send a notification this returns nil. For now, we only care about if
  # the rents have changed at all
  defp notify_reasons(apartments, history) do
    current_records = Enum.reduce(apartments, %{}, fn(a, acc) ->
      Dict.put(acc, a.unit, a.rent)
    end)
    last_recorded = Enum.reduce(history, %{}, fn(entry, acc) ->
      {unit, history} = entry
      sorted_history = Enum.sort(history, fn(a, b) -> hd(b) > hd(a) end) # inverse sort
      last_record = hd(history)
      [last_rent] = tl(last_record)
      Dict.put(acc, unit, last_rent)
    end)
    all_keys = Enum.reduce(Dict.keys(current_records), HashSet.new, fn(r, acc) ->
      HashSet.put(acc, r)
    end)
    updated_all_keys = Enum.reduce(Dict.keys(last_recorded), all_keys, fn(r, acc) ->
      HashSet.put(acc, r)
    end)

    reasons = Enum.reduce(HashSet.to_list(updated_all_keys), %{}, fn(k, acc) ->
      current = Dict.get(current_records, k, nil)
      last = Dict.get(last_recorded, k, nil)
      cond do
        last == nil ->
          Dict.put(acc, k, :new)
        current == nil ->
          Dict.put(acc, k, :gone)
        last != current ->
          Dict.put(acc, k, :changed)
        true ->
          acc
      end
    end)
    if Dict.size(reasons) > 0 do
      reasons
    else
      nil
    end
  end


  defp notify(reasons, apartments) do
    IO.puts "Reasons to notify: #{inspect reasons}"
    IO.puts "About apartments: "
    Enum.map(apartments, fn(a) ->
      IO.puts "\tUnit: #{a.unit}\tBeds: #{a.beds}\tBaths: #{a.baths}"
      IO.puts "\t\tSq Ft: #{a.sqft}"
      IO.puts "\t\tRent: $#{a.rent}"
      if Dict.get(reasons, a.unit) do
        IO.puts "\t*Reason*: #{reasons[a.unit]}"
      end
    end)
  end

end
