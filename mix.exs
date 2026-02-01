defmodule XClient.MixProject do
  use Mix.Project

  @version "1.0.0"
  @source_url "https://github.com/iamkanishka/x-client.ex.git"

  def project do
    [
      app: :x_client,
      version: @version,
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs(),
      name: "XClient",
      source_url: @source_url
    ]
  end

  def application do
    [
      extra_applications: [:logger, :crypto],
      mod: {XClient.Application, []}
    ]
  end

  defp deps do
    [
      # HTTP client
      {:req, "~> 0.4.0"},

      # JSON encoding/decoding
      {:jason, "~> 1.4"},

      # OAuth 1.0a signature
      {:oauther, "~> 1.3"},

      # Rate limiting
      {:ex_rated, "~> 2.1"},

      # MIME type detection for media uploads
      {:mime, "~> 2.0"},

      # Documentation
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},

      # Testing
      {:mox, "~> 1.1", only: :test},
      {:bypass, "~> 2.1", only: :test}
    ]
  end

  defp description do
    """
    A comprehensive Elixir client for X API v1.1 with full endpoint coverage,
    rate limiting, multimedia support, and OAuth 1.0a authentication.
    """
  end

  defp package do
    [
      name: "x_client",
      files: ~w(lib .formatter.exs mix.exs README* LICENSE* CHANGELOG* USAGE_GUIDE* API_REFERENCE*),
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md"
      },
      maintainers: ["Your Name"]
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "CHANGELOG.md"],
      source_ref: "v#{@version}",
      source_url: @source_url
    ]
  end
end
