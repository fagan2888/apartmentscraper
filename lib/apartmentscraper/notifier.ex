defmodule ApartmentScraper.Notifier do

  # Pull out reasons to notify for each unit -- if we end up with no reasons
  # to send a notification this returns nil. For now, we only care about if
  # the rents have changed at all
  def find_reasons(apartments, history) do
    current_records = Enum.reduce(apartments, %{}, fn(a, acc) ->
      Dict.put(acc, a.unit, a.rent)
    end)
    last_recorded = Enum.reduce(history, %{}, fn(entry, acc) ->
      {unit, unit_history} = entry
      sorted_history = Enum.sort(unit_history, fn(a, b) ->
        date_a = hd(a)
        date_b = hd(b)
        date_b < date_a
      end) # inverse sort
      last_record = hd(sorted_history)
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

  def notify(reasons, apartments) do
    IO.puts "Reasons to notify: #{inspect reasons}"
    IO.puts "About apartments: "
    Enum.map(apartments, fn(a) ->
      IO.puts "\tUnit: #{a.unit}\tBeds: #{a.beds}\tBaths: #{a.baths}"
      IO.puts "\t\tSq Ft: #{a.sqft}"
      IO.puts "\t\tRent: $#{trunc a.rent}"
      if Dict.get(reasons, a.unit) do
        IO.puts "\t*Reason*: #{reasons[a.unit]}"
      end
    end)
    annotated_apartments = Enum.reduce(apartments, %{}, fn(a, acc) ->
      Dict.put(acc, a.unit, {a, Dict.get(reasons, a.unit)})
    end)
    # TODO
    send from: "rami.chowdhury@gmail.com", to: ["rami.chowdhury@gmail.com"], subject: "ApartmentScraper update", template: "notifications", data: annotated_apartments
  end

  def compose(email_settings) do
    from = email_settings[:from]
    to_list = email_settings[:to]
    subject = email_settings[:subject]
    template = email_settings[:template]
    data = email_settings[:data]
    email = Mailer.compose_email from, hd(to_list), subject, template, data
    Enum.map(tl(to_list), fn(addr) ->
      Mailer.Email.Multipart.add_to email, addr
    end)
    email
  end

  def send(email_settings) do
    email = compose email_settings
    case Mailer.send(email) do
      {:error, details} ->
        IO.puts :stderr, "Could not send email: #{details}"
      _ ->
        nil # assume this is just fine
    end
  end

end
