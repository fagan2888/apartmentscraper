defmodule ApartmentScraper.Parser.CapitolYards do
  import Floki, only: [find: 2, attribute: 2]
  alias Calendar.Date
  alias ApartmentScraper.ApartmentInfo

  def parse_html(raw) do
    apartment_divs = find raw, "#search_results div[class=result]"
    Enum.map(apartment_divs, &parse_apartment_div/1)
  end

  defp parse_sqft_string(s) do
    # Extract the square-foot size of the apartment as an integer from a
    # descriptive string like '752 sq. ft'
    ~r/(?<sft>\d+)/
      |> Regex.named_captures(s)
      |> Map.get("sft")
      |> Integer.parse
      |> elem(0)
  end

  defp parse_rent_string(s) do
    # Extract the rent dollar amount per month as a float from a string
    # of the form 'From $1858 / Month'
    ~r/\$(?<r>\d+\.\d+)/
      |> Regex.named_captures(s)
      |> Map.get("r")
      |> Float.parse
      |> elem(0)
  end

  defp parse_available_date(s) do
    # Extract the available date as a Calendar.Date from a string of the
    # form 'Available: 07-03-2015'

    date_info = ~r/(\d{2})-(\d{2})-(\d{4})/
      |> Regex.run(s)
      |> tl
      |> Enum.map(&Integer.parse/1)
      |> Enum.map(fn pair -> elem(pair, 0) end)
    [month, day, year] = date_info
    parse_result = Date.from_erl {year, month, day}
    elem(parse_result, 1)
  end

  defp parse_bed_count(n) when n == "Studio" do
    0
  end

  defp parse_bed_count(n) do
    case Integer.parse(n) do
      :error -> IO.puts "Error: #{n} is not an integer"
      {num, _} -> num
    end
  end

  defp parse_apartment_div(div) do
    alias Floki.DeepText
    unit_number = DeepText.get find(div, "span[class=unit]")
    floor = DeepText.get find(div, "span[class=floor]")
    image_small = find(div, "img[class=floorSmall]")
      |> attribute("src")
      |> hd
    image_large = DeepText.get find(div, "span[class=floorLarge]")
    building = find(div, "ul[class=info]")
      |> attribute("data-building-number")
      |> hd
    floorplan = find(div, "ul[class=info]")
      |> attribute("data-floor-plan-name")
      |> hd
    beds = find(div, "li[class=layout]")
      |> DeepText.get
      |> String.split(" ", [parts: 2, trim: true])
      |> hd
      |> parse_bed_count
    baths = find(div, "li[class=bath]")
      |> DeepText.get
      |> String.split(" ", [parts: 2, trim: true])
      |> hd
      |> Integer.parse
      |> elem(0)

    sqft_string = DeepText.get find(div, "li[class=sqft-info]")
    sqft = parse_sqft_string sqft_string

    rent_string = DeepText.get find(div, "li[class=rent]")
    rent = parse_rent_string rent_string

    avail_string = DeepText.get find(div, "li[class=available]")
    avail = parse_available_date avail_string

    %ApartmentInfo{
      unit: unit_number,
      floor: floor,
      building: building,
      beds: beds,
      baths: baths,
      sqft: sqft,
      rent: rent,
      images: [small: image_small, large: image_large],
      available: avail,
      floorplan: floorplan
    }
  end

end
