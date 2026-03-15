# API Reference

Complete reference for all public functions in `XClient` v1.1.1.

> **Type conventions used throughout this document**
>
> - `client` — an optional `%XClient.Client{}` struct. When omitted, application config credentials are used.
> - `opts` — a keyword list of optional parameters. All boolean values are coerced to `"true"` / `"false"` strings automatically.
> - `response()` — `{:ok, term()} | {:error, %XClient.Error{}}`

---

## `XClient`

The top-level module. Use `XClient.client/1` to build per-request credential structs.

### `client(opts \\ []) :: %XClient.Client{}`

Builds an `%XClient.Client{}` struct. Missing keys fall back to application config.

```elixir
client = XClient.client(
  consumer_key: "CK",
  consumer_secret: "CS",
  access_token: "AT",
  access_token_secret: "ATS"
)
```

### `verify_credentials(opts \\ []) :: response()`

Convenience wrapper for `Account.verify_credentials/2`.

```elixir
{:ok, user} = XClient.verify_credentials()
{:ok, user} = XClient.verify_credentials(skip_status: true)
```

---

## `XClient.Tweets`

Endpoint prefix: `statuses/`

### `update(status, opts \\ [], client \\ nil) :: response()`
### `update(client, status, opts \\ []) :: response()`

Posts a new tweet. Multi-account form accepts `client` as first argument.

| Option | Type | Description |
|--------|------|-------------|
| `:in_reply_to_status_id` | string | ID of the tweet being replied to |
| `:media_ids` | `[string]` | Up to 4 media ID strings |
| `:possibly_sensitive` | boolean | Mark media as sensitive |
| `:lat` / `:long` | float | Geo-tag coordinates |
| `:place_id` | string | X Place ID |
| `:trim_user` | boolean | Return only user ID |
| `:tweet_mode` | `"extended"` | Return full text (> 140 chars) |

### `destroy(id, opts \\ [], client \\ nil) :: response()`

Deletes a tweet owned by the authenticated user. Returns the deleted tweet.

### `retweet(id, opts \\ [], client \\ nil) :: response()`

Retweets a tweet.

### `unretweet(id, opts \\ [], client \\ nil) :: response()`

Removes a retweet.

### `show(id, opts \\ [], client \\ nil) :: response()`

Returns a single tweet by ID.

### `lookup(ids, opts \\ [], client \\ nil) :: response()`

Returns up to 100 tweets by a list of IDs. Uses a POST request.

### `user_timeline(opts \\ [], client \\ nil) :: response()`

Returns up to 200 recent tweets from a user's timeline. Requires `:user_id` or `:screen_name`.

| Option | Max | Description |
|--------|-----|-------------|
| `:count` | 200 | Number of tweets |
| `:since_id` | — | Return tweets newer than ID |
| `:max_id` | — | Return tweets at or older than ID |
| `:exclude_replies` | — | Omit reply tweets |
| `:include_rts` | — | Include native retweets |

### `mentions_timeline(opts \\ [], client \\ nil) :: response()`

Returns up to 200 recent @mentions for the authenticated user.

### `retweets_of_me(opts \\ [], client \\ nil) :: response()`

Returns authenticated user's tweets that others have retweeted.

### `retweets(id, opts \\ [], client \\ nil) :: response()`

Returns up to 100 retweets of a given tweet.

### `retweeters_ids(id, opts \\ [], client \\ nil) :: response()`

Returns IDs of users who retweeted a tweet.

**Rate Limits** — `update` / `retweet`: 300 / 3 h | `user_timeline`: 900 / 15 min (user), 1500 / 15 min (app) | `mentions_timeline`: 75 / 15 min

---

## `XClient.Media`

Endpoint prefix: `media/`  Upload base: `https://upload.x.com/1.1`

### `upload(media, opts \\ [], client \\ nil) :: response()`

Uploads media to X. Accepts a file path or binary data. Automatically uses chunked upload for files > 5 MB.

| Option | Description |
|--------|-------------|
| `:media_type` | MIME type string — required for raw binary input; auto-detected for file paths |
| `:media_category` | `"tweet_image"`, `"tweet_gif"`, `"tweet_video"`, `"dm_image"`, `"dm_gif"`, `"dm_video"` |
| `:additional_owners` | List of user IDs who may use this media |
| `:alt_text` | Accessibility description (max 1000 chars) |

```elixir
{:ok, media} = XClient.Media.upload("priv/photo.jpg")
{:ok, media} = XClient.Media.upload("priv/video.mp4", media_category: "tweet_video")

# Binary upload
data = File.read!("priv/image.png")
{:ok, media} = XClient.Media.upload(data, media_type: "image/png")
```

### `chunked_upload(path, opts \\ [], client \\ nil) :: response()`

Explicitly uses the INIT / APPEND / FINALIZE chunked upload flow. Use for large files or when you need to control the chunk size.

### `upload_status(media_id, client \\ nil) :: response()`

Polls processing status for video/GIF uploads. Returns `processing_info` with state: `"pending"`, `"in_progress"`, `"succeeded"`, or `"failed"`.

### `add_metadata(media_id, alt_text, client \\ nil) :: response()`

Adds alt text to an already-uploaded media object.

**Size Limits** — Images: 5 MB | GIFs: 15 MB | Videos: 512 MB

---

## `XClient.Users`

Endpoint prefix: `users/`

### `show(opts \\ [], client \\ nil) :: response()`

Returns a single user. Requires `:user_id` or `:screen_name`.

### `lookup(opts \\ [], client \\ nil) :: response()`

Returns up to 100 users. Pass `:user_id` or `:screen_name` as a list or comma-separated string.

### `search(query, opts \\ [], client \\ nil) :: response()`

Searches for users matching a query string.

| Option | Max | Description |
|--------|-----|-------------|
| `:count` | 20 | Users per page |
| `:page` | — | Page number (1-based) |

### `suggestions(opts \\ [], client \\ nil) :: response()`

Returns suggested user categories.

### `suggestions_slug(slug, opts \\ [], client \\ nil) :: response()`

Returns suggested users for a specific category slug.

### `suggestions_members(slug, client \\ nil) :: response()`

Returns members of a suggested user category.

**Rate Limits** — `show` / `lookup`: 900 / 15 min | `search`: 900 / 15 min (user only) | `suggestions*`: 15 / 15 min

---

## `XClient.Friendships`

Endpoint prefixes: `friendships/`, `followers/`, `friends/`

### `create(opts \\ [], client \\ nil) :: response()`

Follows a user. Requires `:user_id` or `:screen_name`.

### `destroy(opts \\ [], client \\ nil) :: response()`

Unfollows a user. Requires `:user_id` or `:screen_name`.

### `show(opts \\ [], client \\ nil) :: response()`

Returns the relationship between two users. Requires source and target identifiers.

### `followers_ids(opts \\ [], client \\ nil) :: response()`

Returns cursor-paginated follower IDs. Up to 5000 per page.

### `followers_list(opts \\ [], client \\ nil) :: response()`

Returns cursor-paginated follower user objects. Up to 200 per page.

### `friends_ids(opts \\ [], client \\ nil) :: response()`

Returns cursor-paginated following IDs. Up to 5000 per page.

### `friends_list(opts \\ [], client \\ nil) :: response()`

Returns cursor-paginated following user objects. Up to 200 per page.

**Rate Limits** — `create`: 400 / 24 h (user), 1000 / 24 h (app) | `show`: 180 / 15 min | `followers_*` / `friends_*`: 15 / 15 min

---

## `XClient.Favorites`

Endpoint prefix: `favorites/`

### `create(id, opts \\ [], client \\ nil) :: response()`

Likes a tweet.

### `destroy(id, opts \\ [], client \\ nil) :: response()`

Unlikes a tweet.

### `list(opts \\ [], client \\ nil) :: response()`

Returns up to 200 tweets liked by the specified user. Requires `:user_id` or `:screen_name`.

**Rate Limits** — `create`: 1000 / 24 h | `list`: 75 / 15 min

---

## `XClient.DirectMessages`

Endpoint prefix: `direct_messages/events/`

Uses the event-based DM API (not the deprecated `direct_messages/new`).

### `send(recipient_id, text, opts \\ [], client \\ nil) :: response()`

Sends a Direct Message.

| Option | Description |
|--------|-------------|
| `:media_id` | Media ID string to attach |
| `:quick_reply_options` | List of label strings for quick-reply buttons |

```elixir
{:ok, event} = XClient.DirectMessages.send("987654321", "Hello!")

{:ok, event} = XClient.DirectMessages.send("987654321", "Pick one:",
  quick_reply_options: ["Yes", "No", "Maybe"])
```

### `destroy(id, client \\ nil) :: response()`

Deletes a DM event (sender only, within time window).

### `list(opts \\ [], client \\ nil) :: response()`

Returns up to 50 DM events. Supports `:count` and `:cursor` for pagination.

### `show(id, client \\ nil) :: response()`

Returns a single DM event by ID.

**Rate Limits** — `send`: 1000 / 24 h (user), 15000 / 24 h (app) | `list` / `show`: 15 / 15 min

---

## `XClient.Lists`

Endpoint prefix: `lists/`

All list identification options: `:list_id` **or** `:slug` + `:owner_screen_name` / `:owner_id`.

### `list(opts \\ [], client \\ nil) :: response()`
### `statuses(opts \\ [], client \\ nil) :: response()`
### `show(opts \\ [], client \\ nil) :: response()`
### `members(opts \\ [], client \\ nil) :: response()`
### `members_show(opts \\ [], client \\ nil) :: response()`
### `memberships(opts \\ [], client \\ nil) :: response()`
### `ownerships(opts \\ [], client \\ nil) :: response()`
### `subscribers(opts \\ [], client \\ nil) :: response()`
### `subscribers_show(opts \\ [], client \\ nil) :: response()`
### `subscriptions(opts \\ [], client \\ nil) :: response()`

**Rate Limits** — `statuses` / `members`: 900 / 15 min | `show`: 75 / 15 min | `memberships`: 75 / 15 min | others: 15 / 15 min

---

## `XClient.Search`

Endpoint: `search/tweets`

### `tweets(query, opts \\ [], client \\ nil) :: response()`

Searches for recent tweets. Returns `%{"statuses" => [...], "search_metadata" => {...}}`.

| Option | Description |
|--------|-------------|
| `:count` | Max 100 (default 15) |
| `:result_type` | `"mixed"` (default), `"recent"`, `"popular"` |
| `:geocode` | `"lat,long,radius"` e.g. `"37.78,-122.39,5mi"` |
| `:lang` | ISO 639-1 language code |
| `:since_id` / `:max_id` | Pagination anchors |
| `:until` | `"YYYY-MM-DD"` upper date bound |
| `:tweet_mode` | `"extended"` for full text |

**Rate Limits** — 180 / 15 min (user), 450 / 15 min (app)

---

## `XClient.Account`

Endpoint prefix: `account/`

### `verify_credentials(opts \\ [], client \\ nil) :: response()`

Verifies credentials and returns the authenticated user object.

| Option | Description |
|--------|-------------|
| `:include_email` | Requires special app permission |
| `:skip_status` | Exclude most recent tweet |

### `settings(client \\ nil) :: response()`

Returns current account settings (GET).

### `update_settings(opts \\ [], client \\ nil) :: response()`

Updates account settings (POST). Options: `:time_zone`, `:lang`, `:sleep_time_enabled`, etc.

### `update_profile(opts \\ [], client \\ nil) :: response()`

Updates profile fields. Options: `:name` (max 50), `:url` (max 100), `:location` (max 30), `:description` (max 160).

### `update_profile_image(image, opts \\ [], client \\ nil) :: response()`

Updates profile avatar. Accepts file path or binary. Max 700 KB. Formats: GIF, JPG, PNG.

### `update_profile_banner(banner, opts \\ [], client \\ nil) :: response()`

Updates profile banner. Accepts file path or binary. Max 5 MB. Recommended: 1500×500 px.

### `remove_profile_banner(client \\ nil) :: response()`

Removes the profile banner.

**Rate Limits** — `verify_credentials`: 75 / 15 min | `settings` (GET): 15 / 15 min | others: 15 / 15 min

---

## `XClient.Trends`

Endpoint prefix: `trends/`

### `place(id, opts \\ [], client \\ nil) :: response()`

Returns top trending topics for a WOEID location.

```elixir
{:ok, [%{"trends" => trends}]} = XClient.Trends.place(1)           # Worldwide
{:ok, [%{"trends" => trends}]} = XClient.Trends.place(23424848)    # India
{:ok, [%{"trends" => trends}]} = XClient.Trends.place(1, exclude: "hashtags")
```

Common WOEIDs: Worldwide `1`, US `23424977`, UK `23424975`, India `23424848`, Canada `23424775`.

### `available(client \\ nil) :: response()`

Returns all locations that X has trending topic data for.

### `closest(opts \\ [], client \\ nil) :: response()`

Returns locations closest to `:lat` / `:long` coordinates.

**Rate Limits** — All: 75 / 15 min

---

## `XClient.Geo`

Endpoint prefix: `geo/`

### `id(place_id, client \\ nil) :: response()`

Returns information about a known X Place by its alphanumeric ID.

```elixir
{:ok, place} = XClient.Geo.id("df51dec6f4ee2b2c")
```

**Rate Limits** — 75 / 15 min (user only)

---

## `XClient.Help`

Endpoint prefix: `help/`

### `configuration(client \\ nil) :: response()`

Returns X's current configuration (photo size limits, short URL lengths, etc.).

### `languages(client \\ nil) :: response()`

Returns the list of languages supported by X.

### `privacy(client \\ nil) :: response()`

Returns X's Privacy Policy text.

### `tos(client \\ nil) :: response()`

Returns X's Terms of Service text.

**Rate Limits** — All: 15 / 15 min

---

## `XClient.API`

Endpoint prefix: `application/`

### `rate_limit_status(opts \\ [], client \\ nil) :: response()`

Returns current rate limit windows for all or selected resource families.

```elixir
{:ok, %{"resources" => r}} = XClient.API.rate_limit_status()
{:ok, %{"resources" => r}} = XClient.API.rate_limit_status(resources: "statuses,friends")

r["statuses"]["/statuses/user_timeline"]
#=> %{"limit" => 900, "remaining" => 897, "reset" => 1712345678}
```

Valid resource families: `statuses`, `friends`, `followers`, `users`, `search`, `lists`, `direct_messages`, `favorites`, `trends`, `geo`, `account`, `application`, `help`.

**Rate Limits** — 180 / 15 min

---

## `XClient.RateLimiter`

Internal GenServer with ETS-backed reads.

### `check_limit(endpoint) :: :ok | {:error, :rate_limited}`

ETS read — non-blocking. Called automatically before every request when `auto_retry: true`.

### `update_limit(endpoint, info) :: :ok`

Async cast. Called automatically after every successful response to ingest `X-Rate-Limit-*` headers.

### `get_limit_info(endpoint) :: map() | nil`

ETS read. Returns `%{limit: integer, remaining: integer, reset: unix_timestamp}` or `nil`.

### `reset_all() :: :ok`

Clears all stored rate limit windows. Useful in tests.

---

## `XClient.Error`

```elixir
%XClient.Error{
  status: 429,              # HTTP status code
  code: 88,                 # X API error code
  message: "Rate limit…",  # human-readable message
  errors: [%{...}],        # raw errors list from response body
  rate_limit_info: %{       # present on 429 responses
    limit: 900,
    remaining: 0,
    reset: 1712345678
  }
}
```

### Common X API Error Codes

| Code | Meaning |
|------|---------|
| 32 | Could not authenticate you |
| 64 | Account suspended |
| 88 | Rate limit exceeded |
| 89 | Invalid or expired token |
| 130 | Over capacity |
| 131 | Internal error |
| 135 | Timestamp out of bounds |
| 161 | Follow limit reached |
| 179 | Not authorised to see this status |
| 185 | Status update limit reached |
| 187 | Duplicate status |
| 226 | Automated request detected |
| 261 | Application write access suspended |
| 326 | Account locked |

---

## `XClient.Config`

All values can be set via `Application.put_env(:x_client, key, value)` at runtime.

| Function | Default | Description |
|----------|---------|-------------|
| `consumer_key/0` | `nil` | OAuth consumer key |
| `consumer_secret/0` | `nil` | OAuth consumer secret |
| `access_token/0` | `nil` | OAuth access token |
| `access_token_secret/0` | `nil` | OAuth access token secret |
| `base_url/0` | `"https://api.x.com/1.1"` | API base URL |
| `upload_url/0` | `"https://upload.x.com/1.1"` | Media upload URL |
| `auto_retry?/0` | `true` | Enable automatic 429 retry |
| `max_retries/0` | `3` | Maximum retry attempts |
| `retry_base_delay_ms/0` | `1_000` | Backoff base delay in ms |
| `request_timeout_ms/0` | `30_000` | HTTP request timeout in ms |
| `validate!/0` | — | Returns `:ok` or `{:error, {:missing_config, [key]}}` |
