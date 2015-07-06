defmodule ApartmentScraper.Fetcher.CapitolYards do
  def get_dummy_html do
    File.read! "raw_data.html"
  end

  def get_html do
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
