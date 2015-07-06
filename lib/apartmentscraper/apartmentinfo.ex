defmodule ApartmentScraper.ApartmentInfo do
  defstruct [unit: "Unknown",
             building: "Unknown",
             floor: 0,
             beds: 0, baths: 0,
             sqft: 0, rent: 0,
             images: [], floorplan: "Unknown",
             available: Calendar.DateTime.now_utc]
end

defimpl String.Chars, for: ApartmentScraper.ApartmentInfo do
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
