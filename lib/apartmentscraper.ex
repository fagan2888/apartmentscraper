defmodule ApartmentScraper do
  import Floki, only: [find: 2, attribute: 2]
  alias Calendar.Date

  defmodule Apartment do
    defstruct [unit: "Unknown",
             building: "Unknown",
             floor: 0,
             beds: 0, baths: 0,
             sqft: 0, rent: 0,
             images: [], floorplan: "Unknown",
             available: Calendar.DateTime.now_utc]
  end

  defimpl String.Chars, for: Apartment do
    def to_string(a) do
      """
      Unit: #{a.unit}\tFloorplan: #{a.floorplan}
      Building: #{a.building}\tFloor: #{a.floor}
      Beds: #{a.beds}\tBaths: #{a.baths}
      Area: #{a.sqft} sq ft
      Rent: #{a.rent}
      Available: #{Calendar.Date.strftime!(a.available, "%m/%d/%Y")}
      Images:
        Small: #{Keyword.get(a.images, :small)}
        Large: #{Keyword.get(a.images, :large)}

      """
    end
  end


  def run do
    IO.puts "Loading apartments..."
    raw_html = get_html
    IO.puts "Parsing..."
    apartments = parse_html raw_html
    IO.puts "Listing..."
    Enum.map(apartments, fn a -> IO.puts "Unit: #{a.unit}, Beds: #{a.beds}, Baths: #{a.baths}, Rent: #{a.rent}" end)
    # TODO: add email sending (github.com/antp/mailer + Gmail + EEx templates?)
    # TODO: add persisting history & notifying of changes (JSON?)
    # TODO: add flag conditions
  end

  defp parse_html(raw) do
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

  @doc """
  Extract an `ApartmentScraper.Apartment` struct from the HTML tree
  """
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

    %Apartment{
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

  defp get_dummy_html do
    File.read! "raw_data.html"
  end

  defp get_html do
    # curl -X POST
    # -H "Cache-Control: no-cache"
    # -H "Postman-Token: 7c43fc7d-cde5-5bdc-d92d-b89bf059cf07"
    # -H "Content-Type: application/x-www-form-urlencoded"
    # -d 'building%5B%5D=909&bedbath%5B%5D=2&min_rent=0&max_rent=0&vacant=&page='
    # 'http://capitolyardsdc.com/proxy.php?search=1'

    base_url = "http://capitolyardsdc.com/proxy.php?search=1"
    params = ["building[]": "909",
              "bedbath[]": "2",
              "min_rent": "0",
              "max_rent": "0",
              "vacant": "",
              "page": ""]
    encoded_params = URI.encode_query params

    headers = ["Content-Type": "application/x-www-form-urlencoded",
               "Cache-Control": "no-cache",
               "User-Agent": "ApartmentScraper 0.0.1"]
    # IO.puts "POSTing: #{base_url}, body: '#{encoded_params}'"
    response = HTTPotion.post(base_url, [body: encoded_params, headers: headers])
    if HTTPotion.Response.success?(response) do
      response.body
    else
      IO.puts :stderr, "ERROR: #{response.status_code} response:"
      IO.puts :stderr, response.body
      "<html><body><div id='search_result'></div></body></html>"
    end
  end
end
