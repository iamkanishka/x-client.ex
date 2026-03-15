# XClient

[![Hex.pm](https://img.shields.io/hexpm/v/x_client.svg)](https://hex.pm/packages/x_client)
[![Hex Docs](https://img.shields.io/badge/hex-docs-blue.svg)](https://hexdocs.pm/x_client)
[![CI](https://github.com/iamkanishka/x-client.ex/actions/workflows/ci.yml/badge.svg)](https://github.com/iamkanishka/x-client.ex/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A comprehensive, production-grade Elixir client for the **X (Twitter) API v1.1**.

## Features

- ✅ **Full API v1.1 Coverage** — tweets, media, users, friendships, favorites, DMs, lists, search, account, trends, geo, help, and application endpoints
- ✅ **OAuth 1.0a Authentication** — HMAC-SHA1 request signing via `oauther`, using the correct `%OAuther.Credentials{}` struct
- ✅ **ETS-backed Rate Limiting** — non-blocking pre-request checks with `read_concurrency: true`; writes go through the GenServer, reads hit ETS directly
- ✅ **Exponential Backoff Retry** — automatic retry on 429 responses with configurable base delay and max attempts
- ✅ **Chunked Media Uploads** — full INIT / APPEND / FINALIZE flow for videos up to 512 MB
- ✅ **Telemetry** — structured events on every request and rate-limit event
- ✅ **Typed Client Struct** — `%XClient.Client{}` with `@enforce_keys`, replacing the original raw-map pattern
- ✅ **Zero Compiler Warnings** — clean `mix compile`, `mix credo --strict`, and `mix dialyzer`
- ✅ **Shared Param Builder** — `XClient.Params` eliminates the `build_params/1` duplication that existed across 10+ modules in the original codebase

## Installation

Add `x_client` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:x_client, "~> 1.1"}
  ]
end
```

Then run:

```bash
mix deps.get
```

## Configuration

### Via `config.exs`

```elixir
# config/config.exs
config :x_client,
  consumer_key: "YOUR_CONSUMER_KEY",
  consumer_secret: "YOUR_CONSUMER_SECRET",
  access_token: "YOUR_ACCESS_TOKEN",
  access_token_secret: "YOUR_ACCESS_TOKEN_SECRET"
```

### Via environment variables (recommended for production)

```elixir
# config/runtime.exs
config :x_client,
  consumer_key: {:system, "X_CONSUMER_KEY"},
  consumer_secret: {:system, "X_CONSUMER_SECRET"},
  access_token: {:system, "X_ACCESS_TOKEN"},
  access_token_secret: {:system, "X_ACCESS_TOKEN_SECRET"}
```

### Optional tuning

```elixir
config :x_client,
  base_url: "https://api.x.com/1.1",       # default
  upload_url: "https://upload.x.com/1.1",  # default
  auto_retry: true,                         # default
  max_retries: 3,                           # default
  retry_base_delay_ms: 1_000,              # default — doubles each retry
  request_timeout_ms: 30_000              # default
```

## Quick Start

```elixir
# Post a tweet
{:ok, tweet} = XClient.Tweets.update("Hello from Elixir! 🚀")

# Upload an image and attach it to a tweet
{:ok, media} = XClient.Media.upload("priv/photo.jpg")
{:ok, tweet} = XClient.Tweets.update(
  "Check this out!",
  media_ids: [media["media_id_string"]]
)

# Search tweets
{:ok, %{"statuses" => tweets}} = XClient.Search.tweets("elixir lang", count: 100)

# Get a user's timeline
{:ok, tweets} = XClient.Tweets.user_timeline(screen_name: "elixirlang", count: 50)

# Follow a user
{:ok, user} = XClient.Friendships.create(screen_name: "elixirlang")

# Like a tweet
{:ok, tweet} = XClient.Favorites.create("123456789")

# Send a Direct Message
{:ok, event} = XClient.DirectMessages.send("987654321", "Hello!")

# Verify credentials
{:ok, account} = XClient.verify_credentials()
```

## Multi-account Usage

Create a per-request client instead of relying on global config:

```elixir
client = XClient.client(
  consumer_key: "CK",
  consumer_secret: "CS",
  access_token: "AT",
  access_token_secret: "ATS"
)

{:ok, tweet} = XClient.Tweets.update(client, "Tweet from account 2!")
{:ok, user}  = XClient.Users.show([screen_name: "elixirlang"], client)
```

## Error Handling

Every function returns `{:ok, term()}` or `{:error, %XClient.Error{}}`:

```elixir
case XClient.Tweets.update("Hello!") do
  {:ok, tweet} ->
    IO.puts("Posted: #{tweet["id_string"]}")

  {:error, %XClient.Error{status: 429, rate_limit_info: info}} ->
    IO.puts("Rate limited. Resets at #{info[:reset]}")

  {:error, %XClient.Error{status: 401, code: 32}} ->
    IO.puts("Authentication failed")

  {:error, %XClient.Error{status: 403, code: 187}} ->
    IO.puts("Duplicate tweet")

  {:error, %XClient.Error{message: message}} ->
    IO.puts("Error: #{message}")
end
```

## Available Modules

| Module | Endpoints |
|--------|-----------|
| `XClient.Tweets` | update, destroy, retweet, unretweet, show, lookup, user_timeline, mentions_timeline, retweets_of_me, retweets, retweeters_ids |
| `XClient.Media` | upload, chunked_upload, upload_status, add_metadata |
| `XClient.Users` | show, lookup, search, suggestions, suggestions_slug, suggestions_members |
| `XClient.Friendships` | create, destroy, show, followers_ids, followers_list, friends_ids, friends_list |
| `XClient.Favorites` | create, destroy, list |
| `XClient.DirectMessages` | send, destroy, list, show |
| `XClient.Lists` | list, statuses, show, members, members_show, memberships, ownerships, subscribers, subscribers_show, subscriptions |
| `XClient.Search` | tweets |
| `XClient.Account` | verify_credentials, settings, update_settings, update_profile, update_profile_image, update_profile_banner, remove_profile_banner |
| `XClient.Trends` | place, available, closest |
| `XClient.Geo` | id |
| `XClient.Help` | configuration, languages, privacy, tos |
| `XClient.API` | rate_limit_status |

## Media Uploads

### Simple image upload (< 5 MB)

```elixir
# From a file path (MIME type auto-detected)
{:ok, media} = XClient.Media.upload("priv/photo.jpg")

# From binary data (media_type required)
data = File.read!("priv/photo.png")
{:ok, media} = XClient.Media.upload(data, media_type: "image/png")

# With alt text for accessibility
{:ok, media} = XClient.Media.upload("priv/photo.jpg",
  alt_text: "A sunset over the ocean")
```

### Video upload (chunked, up to 512 MB)

```elixir
{:ok, media} = XClient.Media.upload("priv/clip.mp4",
  media_category: "tweet_video")

{:ok, tweet} = XClient.Tweets.update(
  "My new video!",
  media_ids: [media["media_id_string"]]
)
```

### Multiple images (up to 4)

```elixir
media_ids =
  ["img1.jpg", "img2.jpg", "img3.jpg", "img4.jpg"]
  |> Enum.map(fn path ->
    {:ok, media} = XClient.Media.upload(path)
    media["media_id_string"]
  end)

{:ok, tweet} = XClient.Tweets.update("Four photos!", media_ids: media_ids)
```

## Pagination

Cursor-based pagination is supported on all collection endpoints:

```elixir
# First page
{:ok, %{"ids" => ids, "next_cursor" => cursor}} =
  XClient.Friendships.followers_ids(screen_name: "elixirlang")

# Next page
{:ok, %{"ids" => more_ids, "next_cursor" => next_cursor}} =
  XClient.Friendships.followers_ids(screen_name: "elixirlang", cursor: cursor)
```

## Rate Limiting

The library tracks rate limit windows from response headers and blocks requests proactively when a window is exhausted:

```elixir
# Check stored rate limit info for an endpoint
info = XClient.RateLimiter.get_limit_info("statuses/user_timeline.json")
# => %{limit: 900, remaining: 847, reset: 1712345678}

# Check all rate limits from the API
{:ok, limits} = XClient.API.rate_limit_status()
{:ok, limits} = XClient.API.rate_limit_status(resources: "statuses,friends")
```

## Telemetry

Attach to XClient's telemetry events for observability:

```elixir
# In your application.ex start/2 or a dedicated telemetry supervisor
:telemetry.attach_many(
  "my-app-x-client",
  [
    [:x_client, :request, :start],
    [:x_client, :request, :stop],
    [:x_client, :request, :error],
    [:x_client, :rate_limit, :blocked]
  ],
  &MyApp.Telemetry.handle_event/4,
  nil
)

# Event shapes:
# [:x_client, :request, :start]  — %{}, %{method: atom, url: binary, endpoint: binary}
# [:x_client, :request, :stop]   — %{duration_us: integer}, %{status: integer, ...}
# [:x_client, :request, :error]  — %{duration_us: integer}, %{reason: term}
# [:x_client, :rate_limit, :blocked] — %{}, %{endpoint: binary}
```

## Development

```bash
# Install dependencies
mix deps.get

# Run the full check suite
mix check          # format + credo + dialyzer

# Run tests
mix test
mix test.ci        # with coverage

# Generate documentation
mix docs

# Individual checks
mix format --check-formatted
mix credo --strict
mix dialyzer
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/my-feature`)
3. Ensure all checks pass: `mix check`
4. Submit a Pull Request

## License

This project is licensed under the MIT License — see [LICENSE](LICENSE) for details.

## Links

- [Hex Package](https://hex.pm/packages/x_client)
- [HexDocs](https://hexdocs.pm/x_client)
- [GitHub](https://github.com/iamkanishka/x-client.ex)
- [X API v1.1 Documentation](https://developer.x.com/en/docs/x-api/v1)
- [Changelog](CHANGELOG.md)
