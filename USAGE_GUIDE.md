# Usage Guide

Practical patterns and recipes for common tasks with `XClient` v1.1.

---

## Table of Contents

1. [Setup & Configuration](#setup--configuration)
2. [Authentication](#authentication)
3. [Posting Tweets](#posting-tweets)
4. [Reading Timelines](#reading-timelines)
5. [Search](#search)
6. [Media Uploads](#media-uploads)
7. [Users & Relationships](#users--relationships)
8. [Direct Messages](#direct-messages)
9. [Lists](#lists)
10. [Trends](#trends)
11. [Account Management](#account-management)
12. [Error Handling](#error-handling)
13. [Rate Limiting](#rate-limiting)
14. [Multi-Account Usage](#multi-account-usage)
15. [Telemetry & Observability](#telemetry--observability)
16. [Testing Strategies](#testing-strategies)

---

## Setup & Configuration

### Installation

```elixir
# mix.exs
def deps do
  [{:x_client, "~> 1.1"}]
end
```

### Runtime configuration (recommended)

```elixir
# config/runtime.exs
config :x_client,
  consumer_key:        System.fetch_env!("X_CONSUMER_KEY"),
  consumer_secret:     System.fetch_env!("X_CONSUMER_SECRET"),
  access_token:        System.fetch_env!("X_ACCESS_TOKEN"),
  access_token_secret: System.fetch_env!("X_ACCESS_TOKEN_SECRET")
```

### Indirection via `{:system, "ENV_VAR"}` (lazy resolution)

```elixir
# config/config.exs — value resolved at call-time, not at compile-time
config :x_client,
  consumer_key: {:system, "X_CONSUMER_KEY"},
  consumer_secret: {:system, "X_CONSUMER_SECRET"}
```

### Validate credentials at startup

Add to your `Application.start/2` or a supervised task:

```elixir
case XClient.Config.validate!() do
  :ok -> :ok
  {:error, {:missing_config, keys}} ->
    raise "Missing X credentials: #{inspect(keys)}"
end
```

---

## Authentication

All requests are signed automatically using OAuth 1.0a (HMAC-SHA1). No action required on your part beyond configuration.

To verify credentials are working:

```elixir
{:ok, user} = XClient.verify_credentials()
IO.puts("Authenticated as @#{user["screen_name"]}")
```

---

## Posting Tweets

### Simple tweet

```elixir
{:ok, tweet} = XClient.Tweets.update("Hello from Elixir! 🚀")
IO.puts("Posted tweet #{tweet["id_string"]}")
```

### Reply to a tweet

```elixir
{:ok, reply} = XClient.Tweets.update(
  "@elixirlang Thanks for the great language!",
  in_reply_to_status_id: "123456789"
)
```

### Tweet with image

```elixir
{:ok, media} = XClient.Media.upload("priv/photo.jpg")
{:ok, tweet} = XClient.Tweets.update(
  "Look at this photo!",
  media_ids: [media["media_id_string"]]
)
```

### Tweet with up to 4 images

```elixir
paths = ["img1.jpg", "img2.jpg", "img3.jpg", "img4.jpg"]
media_ids = Enum.map(paths, fn path ->
  {:ok, media} = XClient.Media.upload(path)
  media["media_id_string"]
end)

{:ok, tweet} = XClient.Tweets.update("Four photos!", media_ids: media_ids)
```

### Geo-tagged tweet

```elixir
{:ok, tweet} = XClient.Tweets.update(
  "Greetings from San Francisco!",
  lat: 37.7749,
  long: -122.4194,
  display_coordinates: true
)
```

### Delete a tweet

```elixir
{:ok, deleted} = XClient.Tweets.destroy("123456789")
```

### Retweet / unretweet

```elixir
{:ok, _} = XClient.Tweets.retweet("123456789")
{:ok, _} = XClient.Tweets.unretweet("123456789")
```

---

## Reading Timelines

### User timeline (paginated)

```elixir
defmodule MyApp.Timeline do
  def fetch_all(screen_name, acc \\ [], max_id \\ nil) do
    opts = [screen_name: screen_name, count: 200, tweet_mode: "extended"]
    opts = if max_id, do: Keyword.put(opts, :max_id, max_id - 1), else: opts

    case XClient.Tweets.user_timeline(opts) do
      {:ok, []} ->
        acc

      {:ok, tweets} ->
        oldest_id = tweets |> List.last() |> Map.fetch!("id")
        fetch_all(screen_name, acc ++ tweets, oldest_id)

      {:error, error} ->
        {:error, error}
    end
  end
end
```

### Mentions timeline

```elixir
{:ok, mentions} = XClient.Tweets.mentions_timeline(count: 50)
Enum.each(mentions, fn tweet ->
  IO.puts("@#{tweet["user"]["screen_name"]}: #{tweet["text"]}")
end)
```

### Tweets retweeted by others

```elixir
{:ok, retweeted} = XClient.Tweets.retweets_of_me(count: 20)
```

---

## Search

### Basic search

```elixir
{:ok, %{"statuses" => tweets, "search_metadata" => meta}} =
  XClient.Search.tweets("elixir lang", count: 100, result_type: "recent")
```

### Paginating search results backwards

```elixir
defmodule MyApp.Search do
  def collect(query, target \\ 500) do
    fetch_page(query, target, [], nil)
  end

  defp fetch_page(_query, target, acc, _max_id) when length(acc) >= target, do: acc

  defp fetch_page(query, target, acc, max_id) do
    opts = [count: 100, result_type: "recent", tweet_mode: "extended"]
    opts = if max_id, do: Keyword.put(opts, :max_id, max_id - 1), else: opts

    case XClient.Search.tweets(query, opts) do
      {:ok, %{"statuses" => []}} ->
        acc

      {:ok, %{"statuses" => tweets}} ->
        oldest_id = tweets |> List.last() |> Map.fetch!("id")
        fetch_page(query, target, acc ++ tweets, oldest_id)

      {:error, _} = error ->
        error
    end
  end
end
```

### Geo-restricted search

```elixir
{:ok, %{"statuses" => local_tweets}} =
  XClient.Search.tweets("coffee",
    geocode: "37.781157,-122.398720,5mi",
    result_type: "recent",
    count: 50
  )
```

---

## Media Uploads

### Image from file path

```elixir
{:ok, media} = XClient.Media.upload("priv/images/photo.jpg")
# media["media_id_string"] is used when posting
```

### Image from binary

```elixir
image_data = File.read!("priv/images/photo.png")
{:ok, media} = XClient.Media.upload(image_data, media_type: "image/png")
```

### Image with alt text (accessibility)

```elixir
{:ok, media} = XClient.Media.upload("priv/photo.jpg",
  alt_text: "A golden retriever playing fetch on a sunny beach")
```

### Video (auto-chunked for large files)

```elixir
{:ok, media} = XClient.Media.upload("priv/videos/clip.mp4",
  media_category: "tweet_video")

# The library waits for processing to complete automatically.
# Then attach to a tweet:
{:ok, tweet} = XClient.Tweets.update(
  "Check out my video!",
  media_ids: [media["media_id_string"]]
)
```

### Manually check video processing status

```elixir
{:ok, status} = XClient.Media.upload_status("111222333")
case status["processing_info"]["state"] do
  "succeeded" -> IO.puts("Ready!")
  "failed"    -> IO.puts("Processing failed: #{inspect(status["processing_info"]["error"])}")
  state       -> IO.puts("Still processing: #{state}")
end
```

### Animated GIF

```elixir
{:ok, media} = XClient.Media.upload("priv/animation.gif",
  media_category: "tweet_gif")
```

---

## Users & Relationships

### Look up a user

```elixir
{:ok, user} = XClient.Users.show(screen_name: "elixirlang")
{:ok, user} = XClient.Users.show(user_id: "123456")
```

### Look up multiple users

```elixir
{:ok, users} = XClient.Users.lookup(screen_name: ["user1", "user2", "user3"])
{:ok, users} = XClient.Users.lookup(user_id: ["1111", "2222"])
```

### Search for users

```elixir
{:ok, results} = XClient.Users.search("elixir developer", count: 20)
```

### Follow / unfollow

```elixir
{:ok, user} = XClient.Friendships.create(screen_name: "elixirlang")
{:ok, user} = XClient.Friendships.destroy(screen_name: "elixirlang")
```

### Check relationship between two users

```elixir
{:ok, %{"relationship" => rel}} = XClient.Friendships.show(
  source_screen_name: "user_a",
  target_screen_name: "user_b"
)

IO.puts("Following: #{rel["source"]["following"]}")
IO.puts("Followed by: #{rel["source"]["followed_by"]}")
```

### Paginate followers

```elixir
defmodule MyApp.Followers do
  def fetch_all_ids(screen_name) do
    collect(screen_name, [], -1)
  end

  defp collect(_sn, acc, 0), do: {:ok, acc}
  defp collect(screen_name, acc, cursor) do
    case XClient.Friendships.followers_ids(screen_name: screen_name, cursor: cursor) do
      {:ok, %{"ids" => ids, "next_cursor" => next}} ->
        collect(screen_name, acc ++ ids, next)
      {:error, _} = err -> err
    end
  end
end
```

### Like / unlike

```elixir
{:ok, _tweet} = XClient.Favorites.create("123456789")
{:ok, _tweet} = XClient.Favorites.destroy("123456789")
```

### Get liked tweets

```elixir
{:ok, likes} = XClient.Favorites.list(screen_name: "elixirlang", count: 200)
```

---

## Direct Messages

### Send a plain DM

```elixir
{:ok, event} = XClient.DirectMessages.send("987654321", "Hey! How are you?")
```

### Send a DM with media

```elixir
{:ok, media} = XClient.Media.upload("priv/image.jpg", media_category: "dm_image")
{:ok, event} = XClient.DirectMessages.send(
  "987654321",
  "Check out this image!",
  media_id: media["media_id_string"]
)
```

### Send a DM with quick-reply buttons

```elixir
{:ok, event} = XClient.DirectMessages.send(
  "987654321",
  "Would you like to subscribe?",
  quick_reply_options: ["Yes, sign me up!", "No thanks", "Tell me more"]
)
```

### List DMs (with pagination)

```elixir
{:ok, %{"events" => events, "next_cursor" => cursor}} =
  XClient.DirectMessages.list(count: 50)

# Next page
{:ok, %{"events" => more}} =
  XClient.DirectMessages.list(count: 50, cursor: cursor)
```

---

## Lists

### Get your lists

```elixir
{:ok, lists} = XClient.Lists.list()
{:ok, lists} = XClient.Lists.list(screen_name: "elixirlang")
```

### Get tweets from a list

```elixir
{:ok, tweets} = XClient.Lists.statuses(list_id: "123456", count: 100)
{:ok, tweets} = XClient.Lists.statuses(slug: "my-list", owner_screen_name: "me", count: 50)
```

### Get list members

```elixir
{:ok, %{"users" => members, "next_cursor" => cursor}} =
  XClient.Lists.members(list_id: "123456")
```

### Check list membership

```elixir
case XClient.Lists.members_show(list_id: "123456", screen_name: "elixirlang") do
  {:ok, _user}          -> IO.puts("Is a member")
  {:error, %{status: 404}} -> IO.puts("Not a member")
end
```

---

## Trends

### Worldwide trends

```elixir
{:ok, [%{"trends" => trends}]} = XClient.Trends.place(1)
top = Enum.take(trends, 5)
Enum.each(top, fn t -> IO.puts("#{t["name"]} (#{t["tweet_volume"]})") end)
```

### Country/city trends

```elixir
{:ok, [%{"trends" => us_trends}]} = XClient.Trends.place(23424977)  # United States
{:ok, [%{"trends" => ny_trends}]} = XClient.Trends.place(2459115)   # New York City
```

### Find nearby trending locations

```elixir
{:ok, locations} = XClient.Trends.closest(lat: 12.9716, long: 77.5946)  # Bengaluru
```

---

## Account Management

### Update profile

```elixir
{:ok, user} = XClient.Account.update_profile(
  name: "Jane Smith",
  description: "Elixir developer | Open source contributor",
  url: "https://example.com",
  location: "Bengaluru, India"
)
```

### Update profile picture

```elixir
{:ok, user} = XClient.Account.update_profile_image("priv/avatar.jpg")
```

### Update banner

```elixir
{:ok, _} = XClient.Account.update_profile_banner("priv/banner.jpg")
```

### Update settings

```elixir
{:ok, settings} = XClient.Account.update_settings(
  time_zone: "Asia/Kolkata",
  lang: "en"
)
```

---

## Error Handling

### Pattern match on specific errors

```elixir
case XClient.Tweets.update("Hello!") do
  {:ok, tweet} ->
    {:ok, tweet["id_string"]}

  {:error, %XClient.Error{status: 429, rate_limit_info: %{reset: reset}}} ->
    wait_ms = (reset - :os.system_time(:second)) * 1_000
    Process.sleep(max(wait_ms, 0))
    XClient.Tweets.update("Hello!")  # retry

  {:error, %XClient.Error{code: 187}} ->
    {:error, :duplicate_tweet}

  {:error, %XClient.Error{code: 226}} ->
    {:error, :automated_request_detected}

  {:error, %XClient.Error{status: 401}} ->
    {:error, :authentication_failed}

  {:error, %XClient.Error{message: msg}} ->
    {:error, msg}
end
```

### Raising on error (bang-style wrapper)

```elixir
defmodule MyApp.X do
  def update!(text, opts \\ []) do
    case XClient.Tweets.update(text, opts) do
      {:ok, tweet} -> tweet
      {:error, error} -> raise error
    end
  end
end
```

---

## Rate Limiting

### Automatic retry (default behaviour)

When a 429 response is received and `auto_retry: true`, the library:
1. Reads the `X-Rate-Limit-Reset` header
2. Sleeps for `retry_base_delay_ms * 2^attempt` milliseconds
3. Retries up to `max_retries` times

### Disable automatic retry

```elixir
# In config
config :x_client, auto_retry: false

# Or handle 429 manually:
case XClient.Search.tweets("elixir") do
  {:error, %XClient.Error{status: 429, rate_limit_info: info}} ->
    reset_in = info[:reset] - :os.system_time(:second)
    IO.puts("Rate limited for #{reset_in}s")
  result -> result
end
```

### Inspect stored rate limit state

```elixir
# After making a request, the library stores the window info
info = XClient.RateLimiter.get_limit_info("statuses/user_timeline.json")
# => %{limit: 900, remaining: 842, reset: 1712345678}

# Check all limits via the API
{:ok, %{"resources" => r}} = XClient.API.rate_limit_status()
timeline_limit = r["statuses"]["/statuses/user_timeline"]
# => %{"limit" => 900, "remaining" => 842, "reset" => 1712345678}
```

---

## Multi-Account Usage

All public API functions accept an optional `%XClient.Client{}` as their last argument (or first, for `Tweets.update/3`):

```elixir
account_a = XClient.client(
  consumer_key: "CK_A", consumer_secret: "CS_A",
  access_token: "AT_A", access_token_secret: "ATS_A"
)

account_b = XClient.client(
  consumer_key: "CK_B", consumer_secret: "CS_B",
  access_token: "AT_B", access_token_secret: "ATS_B"
)

{:ok, tweet_a} = XClient.Tweets.update(account_a, "Hello from account A!")
{:ok, tweet_b} = XClient.Tweets.update(account_b, "Hello from account B!")

{:ok, timeline} = XClient.Tweets.user_timeline([screen_name: "elixirlang"], account_a)
```

---

## Telemetry & Observability

### Attach a handler

```elixir
# lib/my_app/telemetry.ex
defmodule MyApp.Telemetry do
  def setup do
    :telemetry.attach_many(
      "my-app-x-client",
      [
        [:x_client, :request, :start],
        [:x_client, :request, :stop],
        [:x_client, :request, :error],
        [:x_client, :rate_limit, :blocked]
      ],
      &handle_event/4,
      nil
    )
  end

  def handle_event([:x_client, :request, :stop], %{duration_us: duration}, meta, _) do
    :telemetry.execute(
      [:my_app, :x_api, :request],
      %{duration: duration},
      %{endpoint: meta.endpoint, status: meta.status}
    )
  end

  def handle_event([:x_client, :rate_limit, :blocked], _measurements, %{endpoint: ep}, _) do
    Logger.warning("X API rate limited on #{ep}")
  end

  def handle_event(_event, _measurements, _meta, _config), do: :ok
end
```

### Integrate with LiveDashboard or Prometheus

```elixir
# Using PromEx or TelemetryMetrics
[
  counter("x_client.request.stop.count", tags: [:endpoint, :status]),
  distribution("x_client.request.stop.duration_us",
    unit: {:microsecond, :millisecond},
    tags: [:endpoint]
  ),
  counter("x_client.rate_limit.blocked.count", tags: [:endpoint])
]
```

---

## Testing Strategies

### Using Bypass for HTTP interception

```elixir
defmodule MyApp.XClientTest do
  use ExUnit.Case

  setup do
    bypass = Bypass.open()
    Application.put_env(:x_client, :base_url, "http://localhost:#{bypass.port}")
    Application.put_env(:x_client, :consumer_key, "test_key")
    Application.put_env(:x_client, :consumer_secret, "test_secret")
    Application.put_env(:x_client, :access_token, "test_token")
    Application.put_env(:x_client, :access_token_secret, "test_token_secret")

    on_exit(fn ->
      Application.delete_env(:x_client, :base_url)
      Application.delete_env(:x_client, :consumer_key)
      Application.delete_env(:x_client, :consumer_secret)
      Application.delete_env(:x_client, :access_token)
      Application.delete_env(:x_client, :access_token_secret)
    end)

    {:ok, bypass: bypass}
  end

  test "posts a tweet", %{bypass: bypass} do
    tweet = %{"id_string" => "42", "text" => "Hello!"}

    Bypass.expect_once(bypass, "POST", "/1.1/statuses/update.json", fn conn ->
      conn
      |> Plug.Conn.put_resp_header("content-type", "application/json")
      |> Plug.Conn.send_resp(200, Jason.encode!(tweet))
    end)

    assert {:ok, %{"id_string" => "42"}} = XClient.Tweets.update("Hello!")
  end
end
```

### Using Mox for behaviour-based mocking

```elixir
# test/support/mocks.ex
Mox.defmock(XClient.HTTPMock, for: XClient.HTTPBehaviour)

# In your test
test "handles API errors" do
  XClient.HTTPMock
  |> expect(:get, fn _endpoint, _params, _client, _opts ->
    {:error, %XClient.Error{status: 503, message: "Service unavailable"}}
  end)

  assert {:error, %{status: 503}} = MyApp.X.fetch_timeline("elixirlang")
end
```

### Resetting rate limiter between tests

```elixir
setup do
  XClient.RateLimiter.reset_all()
  :ok
end
```
