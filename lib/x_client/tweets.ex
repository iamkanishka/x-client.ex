defmodule XClient.Tweets do
  @moduledoc """
  Tweet operations for X API v1.1.

  ## Rate Limits

  | Endpoint                         | User auth         | App-only          |
  |----------------------------------|-------------------|-------------------|
  | POST statuses/update             | 300 / 3 h         | —                 |
  | POST statuses/retweet/:id        | 300 / 3 h         | —                 |
  | POST statuses/unretweet/:id      | 300 / 3 h         | —                 |
  | GET  statuses/show/:id           | 900 / 15 min      | 900 / 15 min      |
  | GET  statuses/lookup             | 900 / 15 min      | 300 / 15 min      |
  | GET  statuses/user_timeline      | 900 / 15 min      | 1500 / 15 min     |
  | GET  statuses/mentions_timeline  | 75 / 15 min       | —                 |
  | GET  statuses/retweets_of_me     | 75 / 15 min       | —                 |
  | GET  statuses/retweets/:id       | 75 / 15 min       | 300 / 15 min      |
  | GET  statuses/retweeters/ids     | 75 / 15 min       | 300 / 15 min      |
  """

  alias XClient.{Client, HTTP, Params}

  @type response :: {:ok, term()} | {:error, XClient.Error.t()}
  @type list_response :: {:ok, term()} | {:error, XClient.Error.t()}

  ## ── Write endpoints ─────────────────────────────────────────────────────────

  @doc """
  Posts a new tweet (status update).

  The `status` text is required. A `client` may be passed as the first argument
  for multi-account usage — `XClient.Tweets.update(client, "text", opts)`.

  ## Options

    - `:in_reply_to_status_id` – ID of tweet being replied to
    - `:auto_populate_reply_metadata` – auto-include @mentions from original
    - `:exclude_reply_user_ids` – comma-separated user IDs to exclude from reply
    - `:media_ids` – list of media ID strings (up to 4)
    - `:possibly_sensitive` – `true` if media may be sensitive
    - `:lat` / `:long` – geo-tag coordinates
    - `:place_id` – X Place ID to attach
    - `:display_coordinates` – whether to display exact coordinates
    - `:trim_user` – only return the user ID (smaller payload)
    - `:card_uri` – attach a card to the tweet

  ## Examples

      {:ok, tweet} = XClient.Tweets.update("Hello, X!")

      {:ok, media} = XClient.Media.upload("image.jpg")
      {:ok, tweet} = XClient.Tweets.update(
        "Check this out!",
        media_ids: [media["media_id_string"]]
      )

      {:ok, reply} = XClient.Tweets.update(
        "@user Thanks!",
        in_reply_to_status_id: "123456789"
      )

      # Multi-account
      {:ok, tweet} = XClient.Tweets.update(my_client, "Hello from account 2")
  """
  # Header clause declares defaults once — prevents "defines defaults multiple times" error.
  @spec update(String.t() | Client.t(), keyword() | String.t(), keyword() | Client.t() | nil) ::
          response()
  def update(status_or_client, opts_or_status \\ [], client_or_opts \\ nil)

  def update(%Client{} = client, status, opts) when is_binary(status) do
    params = Params.build(opts, status: status)
    HTTP.post("statuses/update.json", params, client)
  end

  def update(status, opts, client) when is_binary(status) do
    params = Params.build(opts, status: status)
    HTTP.post("statuses/update.json", params, client)
  end

  @doc """
  Deletes a tweet owned by the authenticating user.

  Returns the deleted tweet object.

  ## Options

    - `:trim_user` – only return user ID in the response

  ## Example

      {:ok, deleted_tweet} = XClient.Tweets.destroy("123456789")
  """
  @spec destroy(String.t(), keyword(), Client.t() | nil) :: response()
  def destroy(id, opts \\ [], client \\ nil) when is_binary(id) do
    params = Params.build(opts)
    HTTP.post("statuses/destroy/#{id}.json", params, client)
  end

  @doc """
  Retweets a tweet.

  ## Options

    - `:trim_user` – only return user ID

  ## Example

      {:ok, retweet} = XClient.Tweets.retweet("123456789")
  """
  @spec retweet(String.t(), keyword(), Client.t() | nil) :: response()
  def retweet(id, opts \\ [], client \\ nil) when is_binary(id) do
    params = Params.build(opts)
    HTTP.post("statuses/retweet/#{id}.json", params, client)
  end

  @doc """
  Removes a retweet previously made by the authenticating user.

  ## Example

      {:ok, original_tweet} = XClient.Tweets.unretweet("123456789")
  """
  @spec unretweet(String.t(), keyword(), Client.t() | nil) :: response()
  def unretweet(id, opts \\ [], client \\ nil) when is_binary(id) do
    params = Params.build(opts)
    HTTP.post("statuses/unretweet/#{id}.json", params, client)
  end

  ## ── Read endpoints ──────────────────────────────────────────────────────────

  @doc """
  Returns a single tweet by ID.

  ## Options

    - `:trim_user` – only return user ID
    - `:include_my_retweet` – include the authenticated user's retweet ID
    - `:include_entities` – include entities node
    - `:include_ext_alt_text` – include alt text
    - `:tweet_mode` – `"extended"` for full (> 140 char) text

  ## Example

      {:ok, tweet} = XClient.Tweets.show("123456789")
      {:ok, tweet} = XClient.Tweets.show("123456789", tweet_mode: "extended")
  """
  @spec show(String.t(), keyword(), Client.t() | nil) :: response()
  def show(id, opts \\ [], client \\ nil) when is_binary(id) do
    params = Params.build(opts, id: id)
    HTTP.get("statuses/show.json", params, client)
  end

  @doc """
  Looks up multiple tweets by a list of IDs (max 100).

  ## Options

    - `:include_entities` – include entities node
    - `:trim_user` – only return user ID
    - `:tweet_mode` – `"extended"` for full text

  ## Example

      {:ok, tweets} = XClient.Tweets.lookup(["111", "222", "333"])
  """
  @spec lookup([String.t()], keyword(), Client.t() | nil) :: list_response()
  def lookup(ids, opts \\ [], client \\ nil) when is_list(ids) do
    params = Params.build(opts, id: ids)
    HTTP.post("statuses/lookup.json", params, client)
  end

  @doc """
  Returns the most recent tweets from the specified user's timeline (max 200 per request).

  Requires either `:user_id` or `:screen_name`.

  ## Options

    - `:user_id` / `:screen_name` – target user
    - `:since_id` – return tweets newer than this ID
    - `:count` – tweets per request (max 200)
    - `:max_id` – return tweets at or older than this ID
    - `:trim_user` – only return user ID
    - `:exclude_replies` – exclude reply tweets
    - `:include_rts` – include native retweets
    - `:tweet_mode` – `"extended"` for full text

  ## Example

      {:ok, tweets} = XClient.Tweets.user_timeline(screen_name: "elixirlang", count: 50)
  """
  @spec user_timeline(keyword(), Client.t() | nil) :: list_response()
  def user_timeline(opts \\ [], client \\ nil) do
    params = Params.build(opts)
    HTTP.get("statuses/user_timeline.json", params, client)
  end

  @doc """
  Returns the most recent @mentions for the authenticating user (max 200).

  ## Options

    - `:count` – max 200
    - `:since_id` / `:max_id` – pagination anchors
    - `:trim_user` – only return user ID
    - `:include_entities` – include entities
    - `:tweet_mode` – `"extended"` for full text

  ## Example

      {:ok, mentions} = XClient.Tweets.mentions_timeline(count: 50)
  """
  @spec mentions_timeline(keyword(), Client.t() | nil) :: list_response()
  def mentions_timeline(opts \\ [], client \\ nil) do
    params = Params.build(opts)
    HTTP.get("statuses/mentions_timeline.json", params, client)
  end

  @doc """
  Returns the most recent of the authenticating user's tweets that have been retweeted by others.

  ## Options

    - `:count` – max 100
    - `:since_id` / `:max_id` – pagination anchors
    - `:trim_user` – only return user ID
    - `:include_entities` / `:include_user_entities`

  ## Example

      {:ok, tweets} = XClient.Tweets.retweets_of_me(count: 20)
  """
  @spec retweets_of_me(keyword(), Client.t() | nil) :: list_response()
  def retweets_of_me(opts \\ [], client \\ nil) do
    params = Params.build(opts)
    HTTP.get("statuses/retweets_of_me.json", params, client)
  end

  @doc """
  Returns up to 100 retweets of the given tweet.

  ## Options

    - `:count` – max 100
    - `:trim_user` – only return user ID

  ## Example

      {:ok, retweets} = XClient.Tweets.retweets("123456789", count: 50)
  """
  @spec retweets(String.t(), keyword(), Client.t() | nil) :: list_response()
  def retweets(id, opts \\ [], client \\ nil) when is_binary(id) do
    params = Params.build(opts)
    HTTP.get("statuses/retweets/#{id}.json", params, client)
  end

  @doc """
  Returns user IDs of users who retweeted the given tweet (up to 100).

  ## Options

    - `:count` – max 100
    - `:cursor` – cursor for pagination
    - `:stringify_ids` – return IDs as strings

  ## Example

      {:ok, %{"ids" => ids, "next_cursor" => cursor}} =
        XClient.Tweets.retweeters_ids("123456789")
  """
  @spec retweeters_ids(String.t(), keyword(), Client.t() | nil) :: response()
  def retweeters_ids(id, opts \\ [], client \\ nil) when is_binary(id) do
    params = Params.build(opts, id: id)
    HTTP.get("statuses/retweeters/ids.json", params, client)
  end
end
