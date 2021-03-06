defmodule ApartmentScraper.Mixfile do
  use Mix.Project

  def project do
    [app: :apartmentscraper,
     version: "0.0.1",
     elixir: "~> 1.0",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [:logger, :httpotion]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [
      {:ibrowse, github: "cmullaparthi/ibrowse", tag: "v4.1.1"},
      {:httpotion, "~> 2.1.0"},
      {:floki, "~> 0.3.2"},
      {:calendar, "~> 0.6.8"},
      {:exjsx, "~> 3.1.0"},
      {:timex, github: "bitwalker/timex", tag: "0.14.0", override: true},
      {:mailer, github: "antp/mailer"},
    ]
  end
end
