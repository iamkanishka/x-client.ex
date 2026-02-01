# XClient

[![Hex.pm](https://img.shields.io/hexpm/v/x_client.svg)](https://hex.pm/packages/x_client)
[![Documentation](https://img.shields.io/badge/documentation-gray)](https://hexdocs.pm/x_client)

A comprehensive Elixir client for X API v1.1 with full endpoint coverage, rate limiting, multimedia support, and OAuth 1.0a authentication.

## Features

- ✅ **Full X API v1.1 Coverage** - All GET and POST endpoints implemented
- ✅ **OAuth 1.0a Authentication** - Secure request signing
- ✅ **Rate Limiting** - Automatic rate limit tracking and retry
- ✅ **Multimedia Support** - Upload images, videos, and GIFs
- ✅ **Chunked Uploads** - Handle large video files efficiently
- ✅ **Type Safety** - Comprehensive typespec coverage
- ✅ **Zero Dependencies** - Minimal, focused dependencies
- ✅ **Well Documented** - Extensive documentation with examples

## Installation

Add `x_client` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:x_client, "~> 1.0.0"}
  ]
end
```

Run `mix deps.get` to fetch the dependency.

## Configuration

Add your X API credentials to your config file:

```elixir
# config/config.exs
config :x_client,
  consumer_key: "YOUR_CONSUMER_KEY",
  consumer_secret: "YOUR_CONSUMER_SECRET",
  access_token: "YOUR_ACCESS_TOKEN",
  access_token_secret: "YOUR_ACCESS_TOKEN_SECRET"
```

Or use environment variables:

```elixir
config :x_client,
  consumer_key: {:system, "X_CONSUMER_KEY"},
  consumer_secret: {:system, "X_CONSUMER_SECRET"},
  access_token: {:system, "X_ACCESS_TOKEN"},
  access_token_secret: {:system, "X_ACCESS_TOKEN_SECRET"}
```

### Optional Configuration

```elixir
config :x_client,
  # Custom API base URL (default: "https://api.x.com/1.1")
  base_url: "https://api.x.com/1.1",
  
  # Custom upload URL (default: "https://upload.x.com/1.1")
  upload_url: "https://upload.x.com/1.1",
  
  # Enable automatic retry on rate limits (default: true)
  auto_retry: true,
  
  # Maximum number of retries (default: 3)
  max_retries: 3
```

## Quick Start

```elixir
# Post a tweet
{:ok, tweet} = XClient.Tweets.update("Hello from Elixir! 🚀")

# Upload media and attach to tweet
{:ok, media} = XClient.Media.upload("path/to/image.jpg")
{:ok, tweet} = XClient.Tweets.update(
  "Check out this image!",
  media_ids: [media["media_id_string"]]
)

# Get user timeline
{:ok, tweets} = XClient.Tweets.user_timeline(screen_name: "elixirlang", count: 50)

# Search tweets
{:ok, results} = XClient.Search.tweets("elixir lang", count: 100)

# Follow a user
{:ok, user} = XClient.Friendships.create(screen_name: "elixirlang")

# Like a tweet
{:ok, tweet} = XClient.Favorites.create("123456789")

# Send a direct message
{:ok, message} = XClient.DirectMessages.send("123456", "Hello!")
```

## Available Modules

### Tweets
- `XClient.Tweets` - Post, delete, retweet, and retrieve tweets
  - `update/3` - Post a tweet
  - `destroy/3` - Delete a tweet
  - `retweet/3` - Retweet a tweet
  - `unretweet/3` - Remove retweet
  - `show/3` - Get single tweet
  - `lookup/3` - Get multiple tweets
  - `user_timeline/2` - Get user's tweets
  - `mentions_timeline/2` - Get mentions
  - `retweets_of_me/2` - Get retweeted tweets
  - `retweets/3` - Get retweets of tweet
  - `retweeters_ids/3` - Get retweeter IDs

### Media
- `XClient.Media` - Upload images, videos, and GIFs
  - `upload/3` - Simple upload
  - `chunked_upload/3` - Chunked upload for large files
  - `upload_status/2` - Check processing status
  - `add_metadata/3` - Add alt text

### Users
- `XClient.Users` - User information and search
  - `show/2` - Get user details
  - `lookup/2` - Get multiple users
  - `search/3` - Search users
  - `suggestions/2` - Get suggested categories
  - `suggestions_slug/3` - Get category suggestions
  - `suggestions_members/2` - Get category members

### Friendships
- `XClient.Friendships` - Follow/unfollow operations
  - `create/2` - Follow user
  - `destroy/2` - Unfollow user
  - `show/2` - Get relationship info
  - `followers_ids/2` - Get follower IDs
  - `followers_list/2` - Get follower details
  - `friends_ids/2` - Get following IDs
  - `friends_list/2` - Get following details

### Favorites
- `XClient.Favorites` - Like/unlike tweets
  - `create/3` - Like a tweet
  - `destroy/3` - Unlike a tweet
  - `list/2` - Get liked tweets

### Direct Messages
- `XClient.DirectMessages` - Send and manage DMs
  - `send/4` - Send a DM
  - `destroy/2` - Delete a DM
  - `list/2` - List DMs
  - `show/2` - Get single DM

### Lists
- `XClient.Lists` - Manage X lists
  - `list/2` - Get all lists
  - `statuses/2` - Get list tweets
  - `show/2` - Get list details
  - `members/2` - Get list members
  - `members_show/2` - Check membership
  - `memberships/2` - Get user's memberships
  - `ownerships/2` - Get owned lists
  - `subscribers/2` - Get subscribers
  - `subscribers_show/2` - Check subscription
  - `subscriptions/2` - Get subscriptions

### Search
- `XClient.Search` - Search for tweets
  - `tweets/3` - Search tweets with query

### Account
- `XClient.Account` - Manage account settings
  - `verify_credentials/2` - Verify credentials
  - `update_profile/2` - Update profile
  - `update_profile_image/3` - Update avatar
  - `update_profile_banner/3` - Update banner
  - `remove_profile_banner/1` - Remove banner
  - `update_settings/2` - Update settings
  - `settings/1` - Get settings

### Trends
- `XClient.Trends` - Get trending topics
  - `place/3` - Get trends for location
  - `available/1` - Get available locations
  - `closest/2` - Get closest locations

### Geo
- `XClient.Geo` - Geographic information
  - `id/2` - Get place information

### Help
- `XClient.Help` - API information
  - `configuration/1` - Get API config
  - `languages/1` - Get supported languages
  - `privacy/1` - Get privacy policy
  - `tos/1` - Get terms of service

### Application
- `XClient.Application` - Application-level operations
  - `rate_limit_status/2` - Get rate limit info

## Rate Limiting

The library automatically tracks rate limits and can retry requests when limits are exceeded.

```elixir
# Automatic retry is enabled by default
{:ok, tweet} = XClient.Tweets.update("This will retry if rate limited")

# Disable automatic retry
config :x_client, auto_retry: false

# Check rate limit status
{:ok, status} = XClient.Application.rate_limit_status()
```

## Media Upload Examples

### Simple Image Upload

```elixir
# Upload from file path
{:ok, media} = XClient.Media.upload("path/to/image.jpg")

# Upload with alt text
{:ok, media} = XClient.Media.upload(
  "path/to/image.jpg",
  alt_text: "A beautiful sunset over the ocean"
)

# Use in tweet
{:ok, tweet} = XClient.Tweets.update(
  "Check this out!",
  media_ids: [media["media_id_string"]]
)
```

### Video Upload

```elixir
# Upload video (automatically uses chunked upload for large files)
{:ok, media} = XClient.Media.upload(
  "path/to/video.mp4",
  media_category: "tweet_video"
)

# Wait for processing if needed (handled automatically)
{:ok, tweet} = XClient.Tweets.update(
  "My new video!",
  media_ids: [media["media_id_string"]]
)
```

### Multiple Images

```elixir
# Upload multiple images
images = ["image1.jpg", "image2.jpg", "image3.jpg", "image4.jpg"]

media_ids =
  Enum.map(images, fn path ->
    {:ok, media} = XClient.Media.upload(path)
    media["media_id_string"]
  end)

# Post tweet with multiple images (max 4)
{:ok, tweet} = XClient.Tweets.update(
  "Check out these photos!",
  media_ids: media_ids
)
```

## Advanced Usage

### Custom Client

You can create a client with specific credentials:

```elixir
client = XClient.client(
  consumer_key: "specific_key",
  consumer_secret: "specific_secret",
  access_token: "specific_token",
  access_token_secret: "specific_token_secret"
)

{:ok, tweet} = XClient.Tweets.update(client, "Tweet with custom creds")
```

### Pagination

Many endpoints support pagination with cursors:

```elixir
# Get first page of followers
{:ok, %{"ids" => ids, "next_cursor" => cursor}} = 
  XClient.Friendships.followers_ids(screen_name: "elixirlang")

# Get next page
{:ok, %{"ids" => more_ids, "next_cursor" => next_cursor}} = 
  XClient.Friendships.followers_ids(
    screen_name: "elixirlang",
    cursor: cursor
  )
```

### Error Handling

```elixir
case XClient.Tweets.update("Hello!") do
  {:ok, tweet} ->
    IO.puts("Tweet posted: #{tweet["id_string"]}")

  {:error, %XClient.Error{status: 429} = error} ->
    IO.puts("Rate limited: #{error.message}")

  {:error, %XClient.Error{status: 401}} ->
    IO.puts("Authentication failed")

  {:error, error} ->
    IO.puts("Error: #{error.message}")
end
```

## Rate Limits Reference

See [X's rate limit documentation](https://developer.x.com/en/docs/x-api/v1/rate-limits) for complete details.

### Common Limits

- **Tweets**: 300 per 3 hours (combined with retweets)
- **Follows**: 400 per 24 hours (user), 1000 per 24 hours (app)
- **Likes**: 1000 per 24 hours
- **Direct Messages**: 1000 per 24 hours (user), 15000 per 24 hours (app)
- **Search**: 180 per 15 minutes (user), 450 per 15 minutes (app)

## Development

```bash
# Run tests
mix test

# Generate documentation
mix docs

# Format code
mix format

# Run static analysis
mix dialyzer
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Built with ❤️ for the Elixir community
- Inspired by the node-x-api-v2 library
- Thanks to X for providing the API

## Links

- [Hex Package](https://hex.pm/packages/x_client)
- [Documentation](https://hexdocs.pm/x_client)
- [GitHub Repository](https://github.com/yourusername/x_client)
- [X API Documentation](https://developer.x.com/en/docs/x-api/v1)

## Support

If you encounter any issues or have questions:

1. Check the [documentation](https://hexdocs.pm/x_client)
2. Search [existing issues](https://github.com/yourusername/x_client/issues)
3. Open a new issue with details

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history.