defmodule XClient do
  @moduledoc """
  A comprehensive Elixir client for X API v1.1.

  ## Features

  - Full X API v1.1 endpoint coverage
  - OAuth 1.0a authentication
  - Rate limiting with automatic retry
  - Multimedia upload support (images, videos, GIFs)
  - Chunked media uploads for large files
  - Type-safe request and response handling
  - Comprehensive error handling

  ## Configuration

  Add the following to your `config/config.exs`:

      config :x_client,
        consumer_key: "YOUR_CONSUMER_KEY",
        consumer_secret: "YOUR_CONSUMER_SECRET",
        access_token: "YOUR_ACCESS_TOKEN",
        access_token_secret: "YOUR_ACCESS_TOKEN_SECRET"

  Or use environment variables:

      config :x_client,
        consumer_key: {:system, "X_CONSUMER_KEY"},
        consumer_secret: {:system, "X_CONSUMER_SECRET"},
        access_token: {:system, "X_ACCESS_TOKEN"},
        access_token_secret: {:system, "X_ACCESS_TOKEN_SECRET"}

  ## Usage

      # Post a tweet
      {:ok, tweet} = XClient.Tweets.update("Hello from Elixir!")

      # Upload media and attach to tweet
      {:ok, media} = XClient.Media.upload("path/to/image.jpg")
      {:ok, tweet} = XClient.Tweets.update("Check this out!", media_ids: [media.media_id_string])

      # Get user timeline
      {:ok, tweets} = XClient.Tweets.user_timeline(screen_name: "elixirlang")

      # Search tweets
      {:ok, results} = XClient.Search.tweets("elixir lang", count: 100)

      # Follow a user
      {:ok, user} = XClient.Friendships.create(screen_name: "elixirlang")
  """

  alias XClient.Config

  @doc """
  Creates a client with custom credentials.

  ## Examples

      client = XClient.client(
        consumer_key: "key",
        consumer_secret: "secret",
        access_token: "token",
        access_token_secret: "token_secret"
      )

      XClient.Tweets.update(client, "Hello!")
  """
  def client(opts \\ []) do
    %{
      consumer_key: Keyword.get(opts, :consumer_key) || Config.consumer_key(),
      consumer_secret: Keyword.get(opts, :consumer_secret) || Config.consumer_secret(),
      access_token: Keyword.get(opts, :access_token) || Config.access_token(),
      access_token_secret: Keyword.get(opts, :access_token_secret) || Config.access_token_secret()
    }
  end

  @doc """
  Verifies the client credentials.

  ## Examples

      {:ok, account} = XClient.verify_credentials()
  """
  def verify_credentials(client \\ nil) do
    XClient.Account.verify_credentials(client)
  end
end
