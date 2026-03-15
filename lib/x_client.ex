defmodule XClient do
  @moduledoc """
  A comprehensive Elixir client for X (Twitter) API v1.1.

  ## Features

  - **Full API coverage** — tweets, media, users, friendships, favorites, DMs, lists, search,
    account, trends, geo, help, and application endpoints
  - **OAuth 1.0a** — HMAC-SHA1 request signing via `oauther`
  - **Rate limiting** — ETS-backed, non-blocking pre-request checks + auto exponential-backoff retry
  - **Chunked media uploads** — INIT/APPEND/FINALIZE for large videos
  - **Telemetry** — structured events on every request and rate limit event
  - **Typed client struct** — `%XClient.Client{}` with enforced credential fields
  - **Zero nil-credential surprises** — validates credentials before every request

  ## Quick Start

      # config/config.exs
      config :x_client,
        consumer_key:        {:system, "X_CONSUMER_KEY"},
        consumer_secret:     {:system, "X_CONSUMER_SECRET"},
        access_token:        {:system, "X_ACCESS_TOKEN"},
        access_token_secret: {:system, "X_ACCESS_TOKEN_SECRET"}

      # Post a tweet
      {:ok, tweet} = XClient.Tweets.update("Hello from Elixir! 🚀")

      # Upload media and attach
      {:ok, media} = XClient.Media.upload("path/to/image.jpg")
      {:ok, tweet} = XClient.Tweets.update("Check this!", media_ids: [media["media_id_string"]])

      # Search
      {:ok, %{"statuses" => tweets}} = XClient.Search.tweets("elixir lang", count: 50)

  ## Per-request custom credentials

      client = XClient.client(
        consumer_key: "CK",
        consumer_secret: "CS",
        access_token: "AT",
        access_token_secret: "ATS"
      )

      {:ok, tweet} = XClient.Tweets.update(client, "Tweeting with custom creds")

  ## Error handling

      case XClient.Tweets.update("Hello!") do
        {:ok, tweet}                                  -> IO.inspect(tweet["id_string"])
        {:error, %XClient.Error{status: 429} = err}  -> IO.puts("Rate limited: \#{err.message}")
        {:error, %XClient.Error{status: 401}}         -> IO.puts("Auth failed")
        {:error, %XClient.Error{} = err}              -> IO.puts("Error: \#{err.message}")
      end
  """

  alias XClient.{Client, Config}

  @doc """
  Builds a `%XClient.Client{}` credential struct.

  Any key not provided falls back to the application config (or the
  `{:system, "ENV_VAR"}` indirection). Useful for multi-account scenarios.

  ## Example

      client = XClient.client(
        consumer_key: "CK",
        consumer_secret: "CS",
        access_token: "AT",
        access_token_secret: "ATS"
      )
  """
  @spec client(keyword()) :: Client.t()
  def client(opts \\ []) do
    %Client{
      consumer_key: Keyword.get(opts, :consumer_key) || Config.consumer_key(),
      consumer_secret: Keyword.get(opts, :consumer_secret) || Config.consumer_secret(),
      access_token: Keyword.get(opts, :access_token) || Config.access_token(),
      access_token_secret: Keyword.get(opts, :access_token_secret) || Config.access_token_secret()
    }
  end

  @doc """
  Convenience wrapper for `XClient.Account.verify_credentials/2`.

  Verifies the current (or provided) client's OAuth credentials with the X API.
  """
  @spec verify_credentials(keyword()) :: {:ok, term()} | {:error, XClient.Error.t()}
  def verify_credentials(opts \\ []) when is_list(opts) do
    XClient.HTTP.get("account/verify_credentials.json", XClient.Params.build(opts))
  end
end
