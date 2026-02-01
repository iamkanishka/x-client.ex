# XClient Usage Guide

This guide provides comprehensive examples for using the XClient library.

## Table of Contents

- [Installation](#installation)
- [Configuration](#configuration)
- [Authentication](#authentication)
- [Tweets](#tweets)
- [Media Uploads](#media-uploads)
- [Users](#users)
- [Friendships](#friendships)
- [Favorites](#favorites)
- [Direct Messages](#direct-messages)
- [Search](#search)
- [Lists](#lists)
- [Trends](#trends)
- [Account Management](#account-management)
- [Rate Limiting](#rate-limiting)
- [Error Handling](#error-handling)

## Installation

Add to your `mix.exs`:

```elixir
def deps do
  [
    {:x_client, "~> 1.0.0"}
  ]
end
```

## Configuration

### Basic Configuration

```elixir
# config/config.exs
config :x_client,
  consumer_key: "YOUR_CONSUMER_KEY",
  consumer_secret: "YOUR_CONSUMER_SECRET",
  access_token: "YOUR_ACCESS_TOKEN",
  access_token_secret: "YOUR_ACCESS_TOKEN_SECRET"
```

### Environment Variables

```elixir
config :x_client,
  consumer_key: {:system, "X_CONSUMER_KEY"},
  consumer_secret: {:system, "X_CONSUMER_SECRET"},
  access_token: {:system, "X_ACCESS_TOKEN"},
  access_token_secret: {:system, "X_ACCESS_TOKEN_SECRET"}
```

## Authentication

### Verify Credentials

```elixir
# Verify your credentials are working
case XClient.Account.verify_credentials() do
  {:ok, account} ->
    IO.puts("Authenticated as: @#{account["screen_name"]}")
    
  {:error, error} ->
    IO.puts("Authentication failed: #{error.message}")
end
```

## Tweets

### Post a Tweet

```elixir
# Simple tweet
{:ok, tweet} = XClient.Tweets.update("Hello, X! 🚀")
IO.puts("Tweet ID: #{tweet["id_string"]}")

# Tweet with location
{:ok, tweet} = XClient.Tweets.update(
  "Tweeting from San Francisco!",
  lat: 37.7749,
  long: -122.4194,
  display_coordinates: true
)
```

### Reply to a Tweet

```elixir
{:ok, reply} = XClient.Tweets.update(
  "@username Thanks for the great content!",
  in_reply_to_status_id: "123456789",
  auto_populate_reply_metadata: true
)
```

### Quote Tweet

```elixir
{:ok, quote} = XClient.Tweets.update(
  "This is amazing! 🎉",
  attachment_url: "https://x.com/user/status/123456789"
)
```

### Delete a Tweet

```elixir
{:ok, deleted_tweet} = XClient.Tweets.destroy("123456789")
```

### Retweet

```elixir
{:ok, retweet} = XClient.Tweets.retweet("123456789")

# Unretweet
{:ok, tweet} = XClient.Tweets.unretweet("123456789")
```

### Get a Single Tweet

```elixir
{:ok, tweet} = XClient.Tweets.show("123456789")
IO.puts("Tweet text: #{tweet["text"]}")
IO.puts("Retweet count: #{tweet["retweet_count"]}")
IO.puts("Like count: #{tweet["favorite_count"]}")
```

### Get Multiple Tweets

```elixir
tweet_ids = ["123456789", "987654321", "456789123"]
{:ok, tweets} = XClient.Tweets.lookup(tweet_ids)

Enum.each(tweets, fn tweet ->
  IO.puts("@#{tweet["user"]["screen_name"]}: #{tweet["text"]}")
end)
```

### User Timeline

```elixir
# Get recent tweets from a user
{:ok, tweets} = XClient.Tweets.user_timeline(
  screen_name: "elixirlang",
  count: 50,
  exclude_replies: false,
  include_rts: true
)

Enum.each(tweets, fn tweet ->
  IO.puts("[#{tweet["created_at"]}] #{tweet["text"]}")
end)
```

### Mentions Timeline

```elixir
# Get your mentions
{:ok, mentions} = XClient.Tweets.mentions_timeline(count: 100)

Enum.each(mentions, fn mention ->
  IO.puts("@#{mention["user"]["screen_name"]} mentioned you: #{mention["text"]}")
end)
```

### Get Retweets

```elixir
# Get users who retweeted
{:ok, retweets} = XClient.Tweets.retweets("123456789", count: 100)

# Get retweeter IDs
{:ok, %{"ids" => ids}} = XClient.Tweets.retweeters_ids("123456789")
```

## Media Uploads

### Upload an Image

```elixir
# Simple upload
{:ok, media} = XClient.Media.upload("path/to/image.jpg")

# Upload with alt text for accessibility
{:ok, media} = XClient.Media.upload(
  "path/to/image.jpg",
  alt_text: "A beautiful sunset over the ocean"
)

# Post tweet with image
{:ok, tweet} = XClient.Tweets.update(
  "Check out this photo!",
  media_ids: [media["media_id_string"]]
)
```

### Upload Multiple Images

```elixir
# Upload up to 4 images
image_paths = ["img1.jpg", "img2.jpg", "img3.jpg", "img4.jpg"]

media_ids = 
  Enum.map(image_paths, fn path ->
    {:ok, media} = XClient.Media.upload(path)
    media["media_id_string"]
  end)

{:ok, tweet} = XClient.Tweets.update(
  "Photo gallery! 📸",
  media_ids: media_ids
)
```

### Upload a Video

```elixir
# Video upload (automatically uses chunked upload if large)
{:ok, media} = XClient.Media.upload(
  "path/to/video.mp4",
  media_category: "tweet_video"
)

# The library automatically waits for processing
{:ok, tweet} = XClient.Tweets.update(
  "My new video!",
  media_ids: [media["media_id_string"]]
)
```

### Upload a GIF

```elixir
{:ok, media} = XClient.Media.upload(
  "path/to/animation.gif",
  media_category: "tweet_gif"
)

{:ok, tweet} = XClient.Tweets.update(
  "Awesome GIF!",
  media_ids: [media["media_id_string"]]
)
```

### Upload from Binary Data

```elixir
# Read file into memory
image_binary = File.read!("image.jpg")

{:ok, media} = XClient.Media.upload(
  image_binary,
  media_type: "image/jpeg",
  alt_text: "Description of image"
)
```

### Check Processing Status

```elixir
{:ok, status} = XClient.Media.upload_status(media_id)

case status["processing_info"]["state"] do
  "succeeded" -> IO.puts("Processing complete!")
  "pending" -> IO.puts("Processing pending...")
  "in_progress" -> IO.puts("Still processing...")
  "failed" -> IO.puts("Processing failed")
end
```

## Users

### Get User Information

```elixir
# By screen name
{:ok, user} = XClient.Users.show(screen_name: "elixirlang")

IO.puts("Name: #{user["name"]}")
IO.puts("Bio: #{user["description"]}")
IO.puts("Followers: #{user["followers_count"]}")
IO.puts("Following: #{user["friends_count"]}")

# By user ID
{:ok, user} = XClient.Users.show(user_id: "123456")
```

### Lookup Multiple Users

```elixir
# By screen names
{:ok, users} = XClient.Users.lookup(
  screen_name: ["elixirlang", "josevalim", "chris_mccord"]
)

# By user IDs
{:ok, users} = XClient.Users.lookup(
  user_id: ["123456", "789012", "345678"]
)

Enum.each(users, fn user ->
  IO.puts("@#{user["screen_name"]}: #{user["description"]}")
end)
```

### Search Users

```elixir
{:ok, users} = XClient.Users.search("elixir developer", count: 20)

Enum.each(users, fn user ->
  IO.puts("@#{user["screen_name"]} - #{user["name"]}")
end)
```

## Friendships

### Follow a User

```elixir
# By screen name
{:ok, user} = XClient.Friendships.create(screen_name: "elixirlang")
IO.puts("Now following @#{user["screen_name"]}")

# By user ID with notifications
{:ok, user} = XClient.Friendships.create(
  user_id: "123456",
  follow: true  # Enable notifications
)
```

### Unfollow a User

```elixir
{:ok, user} = XClient.Friendships.destroy(screen_name: "example")
IO.puts("Unfollowed @#{user["screen_name"]}")
```

### Check Relationship

```elixir
{:ok, relationship} = XClient.Friendships.show(
  source_screen_name: "me",
  target_screen_name: "elixirlang"
)

source = relationship["relationship"]["source"]
target = relationship["relationship"]["target"]

IO.puts("Following: #{source["following"]}")
IO.puts("Followed by: #{source["followed_by"]}")
```

### Get Followers

```elixir
# Get follower IDs (up to 5000 per page)
{:ok, %{"ids" => ids, "next_cursor" => cursor}} = 
  XClient.Friendships.followers_ids(
    screen_name: "elixirlang",
    count: 5000
  )

IO.puts("Found #{length(ids)} followers")

# Get follower details
{:ok, %{"users" => users, "next_cursor" => cursor}} = 
  XClient.Friendships.followers_list(
    screen_name: "elixirlang",
    count: 200
  )

Enum.each(users, fn user ->
  IO.puts("@#{user["screen_name"]} - #{user["name"]}")
end)
```

### Get Following

```elixir
# Get IDs of users you're following
{:ok, %{"ids" => ids}} = XClient.Friendships.friends_ids(
  screen_name: "elixirlang"
)

# Get details
{:ok, %{"users" => users}} = XClient.Friendships.friends_list(
  screen_name: "elixirlang",
  count: 200
)
```

### Pagination Example

```elixir
defmodule FollowerFetcher do
  def fetch_all_followers(screen_name) do
    fetch_page(screen_name, -1, [])
  end

  defp fetch_page(screen_name, cursor, acc) do
    {:ok, %{"ids" => ids, "next_cursor" => next_cursor}} = 
      XClient.Friendships.followers_ids(
        screen_name: screen_name,
        cursor: cursor
      )

    new_acc = acc ++ ids

    if next_cursor == 0 do
      new_acc
    else
      # Add delay to respect rate limits
      Process.sleep(1000)
      fetch_page(screen_name, next_cursor, new_acc)
    end
  end
end

# Usage
all_followers = FollowerFetcher.fetch_all_followers("elixirlang")
IO.puts("Total followers: #{length(all_followers)}")
```

## Favorites

### Like a Tweet

```elixir
{:ok, tweet} = XClient.Favorites.create("123456789")
IO.puts("Liked tweet by @#{tweet["user"]["screen_name"]}")
```

### Unlike a Tweet

```elixir
{:ok, tweet} = XClient.Favorites.destroy("123456789")
```

### Get Liked Tweets

```elixir
# Get your liked tweets
{:ok, favorites} = XClient.Favorites.list(count: 200)

# Get someone else's liked tweets
{:ok, favorites} = XClient.Favorites.list(
  screen_name: "elixirlang",
  count: 100
)

Enum.each(favorites, fn tweet ->
  IO.puts("[#{tweet["created_at"]}] #{tweet["text"]}")
end)
```

## Direct Messages

### Send a DM

```elixir
# Simple text message
{:ok, message} = XClient.DirectMessages.send(
  "123456",  # recipient user ID
  "Hello! Thanks for following."
)

# With media attachment
{:ok, media} = XClient.Media.upload("image.jpg")
{:ok, message} = XClient.DirectMessages.send(
  "123456",
  "Check this out!",
  media_id: media["media_id_string"]
)

# With quick reply options
{:ok, message} = XClient.DirectMessages.send(
  "123456",
  "How can I help you?",
  quick_reply_options: ["Support", "Sales", "General Question"]
)
```

### List DMs

```elixir
{:ok, %{"events" => messages}} = XClient.DirectMessages.list(count: 50)

Enum.each(messages, fn event ->
  message = event["message_create"]["message_data"]
  IO.puts("Message: #{message["text"]}")
end)
```

### Get a Single DM

```elixir
{:ok, event} = XClient.DirectMessages.show("123456789")
```

### Delete a DM

```elixir
{:ok, _} = XClient.DirectMessages.destroy("123456789")
```

## Search

### Basic Search

```elixir
{:ok, %{"statuses" => tweets}} = XClient.Search.tweets(
  "elixir lang",
  count: 100
)

Enum.each(tweets, fn tweet ->
  IO.puts("@#{tweet["user"]["screen_name"]}: #{tweet["text"]}")
end)
```

### Advanced Search with Filters

```elixir
# Search with geocoding
{:ok, results} = XClient.Search.tweets(
  "coffee",
  geocode: "37.7749,-122.4194,5mi",  # San Francisco, 5 mile radius
  result_type: "recent",
  count: 100
)

# Search with language filter
{:ok, results} = XClient.Search.tweets(
  "phoenix framework",
  lang: "en",
  result_type: "popular"
)

# Search with date range
{:ok, results} = XClient.Search.tweets(
  "elixir",
  until: "2024-12-31",
  count: 100
)
```

### Search Operators

```elixir
# Exact phrase
XClient.Search.tweets("\"elixir phoenix\"")

# Multiple words
XClient.Search.tweets("elixir AND phoenix")

# Exclude words
XClient.Search.tweets("elixir -java")

# From specific user
XClient.Search.tweets("from:elixirlang")

# To specific user
XClient.Search.tweets("to:josevalim")

# Mentions
XClient.Search.tweets("@elixirlang")

# Hashtags
XClient.Search.tweets("#myelixirstatus")

# Positive sentiment
XClient.Search.tweets("elixir :)")

# Questions only
XClient.Search.tweets("elixir ?")

# With links
XClient.Search.tweets("elixir filter:links")
```

## Lists

### Get All Lists

```elixir
{:ok, lists} = XClient.Lists.list()

Enum.each(lists, fn list ->
  IO.puts("#{list["name"]} - #{list["member_count"]} members")
end)
```

### Get List Timeline

```elixir
{:ok, tweets} = XClient.Lists.statuses(
  list_id: "123456",
  count: 100
)

# Or by slug and owner
{:ok, tweets} = XClient.Lists.statuses(
  slug: "team",
  owner_screen_name: "x",
  count: 100
)
```

### Get List Members

```elixir
{:ok, %{"users" => members}} = XClient.Lists.members(
  list_id: "123456",
  count: 100
)

Enum.each(members, fn user ->
  IO.puts("@#{user["screen_name"]} - #{user["name"]}")
end)
```

### Check List Membership

```elixir
case XClient.Lists.members_show(
  list_id: "123456",
  screen_name: "elixirlang"
) do
  {:ok, user} -> IO.puts("User is a member")
  {:error, _} -> IO.puts("User is not a member")
end
```

## Trends

### Get Trending Topics

```elixir
# Worldwide trends
{:ok, [%{"trends" => trends}]} = XClient.Trends.place(1)

Enum.each(trends, fn trend ->
  IO.puts("#{trend["name"]} - #{trend["tweet_volume"]} tweets")
end)

# US trends
{:ok, [%{"trends" => trends}]} = XClient.Trends.place(23424977)

# New York trends
{:ok, [%{"trends" => trends}]} = XClient.Trends.place(2459115)
```

### Get Available Trend Locations

```elixir
{:ok, locations} = XClient.Trends.available()

Enum.each(locations, fn location ->
  IO.puts("#{location["name"]} (WOEID: #{location["woeid"]})")
end)
```

### Find Closest Trend Location

```elixir
{:ok, [location]} = XClient.Trends.closest(
  lat: 37.7749,
  long: -122.4194
)

IO.puts("Closest location: #{location["name"]}")
```

## Account Management

### Update Profile

```elixir
{:ok, user} = XClient.Account.update_profile(
  name: "New Display Name",
  description: "Elixir developer | Phoenix enthusiast",
  location: "San Francisco, CA",
  url: "https://example.com"
)
```

### Update Profile Image

```elixir
{:ok, user} = XClient.Account.update_profile_image("path/to/avatar.jpg")
```

### Update Profile Banner

```elixir
{:ok, _} = XClient.Account.update_profile_banner("path/to/banner.jpg")
```

### Get Account Settings

```elixir
{:ok, settings} = XClient.Account.settings()
IO.puts("Time zone: #{settings["time_zone"]["name"]}")
IO.puts("Language: #{settings["language"]}")
```

## Rate Limiting

### Check Rate Limit Status

```elixir
# Get all rate limits
{:ok, limits} = XClient.Application.rate_limit_status()

# Get specific resource limits
{:ok, limits} = XClient.Application.rate_limit_status(
  resources: "statuses,users,search"
)

# Check specific endpoint
statuses = limits["resources"]["statuses"]
user_timeline = statuses["/statuses/user_timeline"]

IO.puts("Limit: #{user_timeline["limit"]}")
IO.puts("Remaining: #{user_timeline["remaining"]}")
IO.puts("Resets at: #{user_timeline["reset"]}")
```

### Handle Rate Limits Manually

```elixir
case XClient.Tweets.user_timeline(screen_name: "elixirlang") do
  {:ok, tweets} ->
    IO.puts("Got #{length(tweets)} tweets")

  {:error, %{status: 429, rate_limit_info: info}} ->
    reset_time = DateTime.from_unix!(info[:reset])
    wait_seconds = DateTime.diff(reset_time, DateTime.utc_now())
    IO.puts("Rate limited. Wait #{wait_seconds} seconds")

  {:error, error} ->
    IO.puts("Error: #{error.message}")
end
```

## Error Handling

### Comprehensive Error Handling

```elixir
defmodule TweetPoster do
  def post_with_retry(text, max_retries \\ 3) do
    do_post(text, 0, max_retries)
  end

  defp do_post(text, attempt, max_retries) when attempt < max_retries do
    case XClient.Tweets.update(text) do
      {:ok, tweet} ->
        {:ok, tweet}

      {:error, %{status: 429}} when attempt < max_retries - 1 ->
        # Rate limited, wait and retry
        wait_time = :math.pow(2, attempt) * 1000 |> round()
        Process.sleep(wait_time)
        do_post(text, attempt + 1, max_retries)

      {:error, %{status: 403}} ->
        {:error, "Forbidden - check credentials or tweet content"}

      {:error, %{status: 401}} ->
        {:error, "Unauthorized - check authentication"}

      {:error, %{status: 404}} ->
        {:error, "Not found"}

      {:error, error} ->
        {:error, "Unknown error: #{error.message}"}
    end
  end

  defp do_post(_text, _attempt, _max_retries) do
    {:error, "Max retries exceeded"}
  end
end

# Usage
case TweetPoster.post_with_retry("Hello!") do
  {:ok, tweet} -> IO.puts("Posted: #{tweet["id_string"]}")
  {:error, reason} -> IO.puts("Failed: #{reason}")
end
```

## Advanced Examples

### Bot that Replies to Mentions

```elixir
defmodule MentionBot do
  def run do
    # Get last processed mention ID from storage
    since_id = get_last_mention_id()

    {:ok, mentions} = XClient.Tweets.mentions_timeline(
      since_id: since_id,
      count: 200
    )

    Enum.each(mentions, &process_mention/1)

    # Save last processed ID
    if length(mentions) > 0 do
      save_last_mention_id(hd(mentions)["id_string"])
    end
  end

  defp process_mention(mention) do
    tweet_id = mention["id_string"]
    username = mention["user"]["screen_name"]
    text = mention["text"]

    # Generate reply
    reply_text = "@#{username} Thanks for your mention!"

    {:ok, _reply} = XClient.Tweets.update(
      reply_text,
      in_reply_to_status_id: tweet_id,
      auto_populate_reply_metadata: true
    )

    IO.puts("Replied to @#{username}")
  end

  defp get_last_mention_id, do: nil  # Implement storage
  defp save_last_mention_id(_id), do: :ok  # Implement storage
end
```

### Scheduled Tweet Poster

```elixir
defmodule ScheduledPoster do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def schedule_tweet(text, datetime) do
    GenServer.cast(__MODULE__, {:schedule, text, datetime})
  end

  @impl true
  def init(_opts) do
    {:ok, %{scheduled: []}}
  end

  @impl true
  def handle_cast({:schedule, text, datetime}, state) do
    delay = DateTime.diff(datetime, DateTime.utc_now(), :millisecond)

    if delay > 0 do
      Process.send_after(self(), {:post, text}, delay)
      {:noreply, %{state | scheduled: [{text, datetime} | state.scheduled]}}
    else
      {:noreply, state}
    end
  end

  @impl true
  def handle_info({:post, text}, state) do
    case XClient.Tweets.update(text) do
      {:ok, tweet} ->
        IO.puts("Posted scheduled tweet: #{tweet["id_string"]}")

      {:error, error} ->
        IO.puts("Failed to post: #{error.message}")
    end

    {:noreply, state}
  end
end
```

This comprehensive guide covers all major features of the XClient library. Refer to the module documentation for complete parameter details and additional options.