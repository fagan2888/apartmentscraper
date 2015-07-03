defmodule ApartmentScraper do
  import Floki, only: [find: 2, attribute: 2]

  defmodule Apartment do
    defstruct [unit: "Unknown",
             building: "Unknown",
             floor: 0,
             beds: 0, baths: 0,
             sqft: 0, rent: 0,
             images: [], floorplan: "Unknown",
             available: Calendar.DateTime.now_utc]
  end

  def run do
    IO.puts "Loading apartments..."
    raw_html = get_dummy_html
    IO.puts "Parsing..."
    parsed = parse_html raw_html
    IO.puts "Parsed:"
    IO.puts parsed
  end

  defp parse_html(raw) do
    apartments = find raw, "#search_results div[class=result]"
    Enum.map(Enum.take(apartments, 1), &parse_apartment_div/1)
  end

  defp parse_apartment_div(div) do
    alias Floki.DeepText
    unit_number = DeepText.get find(div, "span[class=unit]")
    floor = DeepText.get find(div, "span[class=floor]")
    image_small_attr = attribute(find(div, "img[class=floorSmall]"), "src")
    image_small = hd(image_small_attr)
    building_attr = attribute(find(div, "ul[class=info]"), "data-building-number")
    building = hd(building_attr)
    floorplan_attr = attribute(find(div, "ul[class=info]"), "data-floor-plan-name")
    floorplan = hd(floorplan_attr)
    beds = DeepText.get find(div, "li[class=layout]")
    baths = DeepText.get find(div, "li[class=bath]")
    sqft = DeepText.get find(div, "li[class=sqft-info]")
    rent = DeepText.get find(div, "li[class=rent]")
    avail = DeepText.get find(div, "li[class=available]")
    image_large = DeepText.get find(div, "span[class=floorLarge]")

    %Apartment{
      unit: unit_number,
      floor: floor,
      building: building,
      beds: beds, # TODO: split
      baths: baths, # TODO: split
      sqft: sqft, # TODO: parse
      rent: rent, # TODO: parse
      images: [small: image_small, large: image_large],
      available: avail, # TODO: parse
      floorplan: floorplan
    }
  end

  defp get_dummy_html do
    File.read! "raw_data.html"
  end

  defp get_html do
    base_url = "http://capitolyardsdc.com/proxy.php?search=1"
    params = ["building[]": "909",
              "bedbath[]": "2",
              "min_rent": "0",
              "max_rent": "0"]
    # "page": nil]
    encoded_params = URI.encode_query params
    headers = ["User-Agent": "ApartmentScraper 0.0.1"]
    response = HTTPotion.post base_url, [body: encoded_params, headers: headers]
    response.body
  end
end
