defmodule ApartmentScraper do
  alias ApartmentScraper.Fetcher
  alias ApartmentScraper.Parser
  alias ApartmentScraper.Persister
  alias ApartmentScraper.Notifier

  def run do
    IO.puts "Loading apartments (Capitol Yards)..."
    raw_html = Fetcher.CapitolYards.get_html
    IO.puts "Parsing..."
    apartments = Parser.CapitolYards.parse_html raw_html
    IO.puts "Notifying..."
    history = Persister.load_rents
    reasons_to_notify = Notifier.find_reasons apartments, history
    if reasons_to_notify do
      Notifier.notify reasons_to_notify, apartments
    end
    IO.puts "Saving..."
    Persister.save_rents apartments, history
  end

end
