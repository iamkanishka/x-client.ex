defmodule XClient.MixProject do
  use Mix.Project

  @version "1.1.1"
  @source_url "https://github.com/iamkanishka/x-client.ex"

  def project do
    [
      app: :x_client,
      version: @version,
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs(),
      name: "XClient",
      source_url: @source_url,
      dialyzer: [
        plt_add_apps: [:ex_unit, :mix],
        plt_core_path: "priv/plts",
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
        flags: [:error_handling, :missing_return, :underspecs],
        ignore_warnings: ".dialyzer_ignore.exs"
      ],
      aliases: aliases()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :crypto],
      mod: {XClient.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      # ── Runtime ───────────────────────────────────────────
      {:req, "~> 0.4"},
      {:jason, "~> 1.4"},
      {:oauther, "~> 1.3"},
      {:mime, "~> 2.0"},
      {:telemetry, "~> 1.2"},

      # ── Documentation ─────────────────────────────────────
      {:ex_doc, "~> 0.40", only: :dev, runtime: false},

      # ── Static analysis ───────────────────────────────────
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},

      # ── Testing ───────────────────────────────────────────
      {:mox, "~> 1.2", only: :test},
      {:bypass, "~> 2.1", only: :test}
    ]
  end

  defp description do
    """
    A comprehensive Elixir client for X (Twitter) API v1.1 with full endpoint coverage,
    built-in rate limiting, chunked media uploads, OAuth 1.0a, telemetry, and zero-config
    environment-variable support.
    """
  end

  defp package do
    [
      name: "x_client",
      files:
        ~w(lib config .formatter.exs mix.exs README* LICENSE* CHANGELOG* USAGE_GUIDE* API_REFERENCE*),
      licenses: ["MIT"],
      maintainers: ["iamkanishka"],
      links: %{
        "GitHub" => @source_url,
        "Changelog" => "#{@source_url}/blob/master/CHANGELOG.md",
        "API Reference" => "#{@source_url}/blob/master/API_REFERENCE.md",
        "Usage Guide" => "#{@source_url}/blob/master/USAGE_GUIDE.md",
        "X API Docs" => "https://developer.x.com/en/docs/x-api/v1"
      }
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"],
      source_ref: "v#{@version}",
      source_url: @source_url,
      groups_for_modules: [
        "API Modules": [
          XClient.Tweets,
          XClient.Media,
          XClient.Users,
          XClient.Friendships,
          XClient.Favorites,
          XClient.DirectMessages,
          XClient.Lists,
          XClient.Search,
          XClient.Account,
          XClient.Trends,
          XClient.Geo,
          XClient.Help,
          XClient.API
        ],
        Internals: [
          XClient.Auth,
          XClient.HTTP,
          XClient.Config,
          XClient.RateLimiter,
          XClient.Error,
          XClient.Client
        ]
      ]
    ]
  end

  defp aliases do
    [
      check: [
        "format --check-formatted",
        "credo --strict",
        "dialyzer"
      ],
      "test.ci": [
        "test --cover --warnings-as-errors"
      ],
      # Quality checks
      quality: [
        "format --check-formatted",
        "credo --strict",
        "dialyzer"
      ]
    ]
  end
end
