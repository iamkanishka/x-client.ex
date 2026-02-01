defmodule XClient.Tweets do
  @moduledoc """
  Tweet operations for X API v1.1.

  ## Rate Limits

  - POST statuses/update: 300 per 3 hours (combined with retweet)
  - POST statuses/retweet/:id: 300 per 3 hours (combined with update)
  - GET statuses/show/:id: 900 per 15 minutes (user), 900 per 15 minutes (app)
  - GET statuses/user_timeline: 900 per 15 minutes (user), 1500 per 15 minutes (app)
  - GET statuses/mentions_timeline: 75 per 15 minutes (user only)
  - GET statuses/retweets_of_me: 75 per 15 minutes (user only)
  - GET statuses/lookup: 900 per 15 minutes (user), 300 per 15 minutes (app)
  - GET statuses/retweeters/ids: 75 per 15 minutes (user), 300 per 15 minutes (app)
  - GET statuses/retweets/:id: 75 per 15 minutes (user), 300 per 15 minutes (app)
  """

  alias XClient.HTTP

  @doc """
  Posts a new tweet.

  ## Parameters

    - `status` - The text of the tweet (required)
    - `opts` - Optional parameters
      - `:in_reply_to_status_id` - The ID of an existing status to reply to
      - `:auto_populate_reply_metadata` - If true, @mentions will be looked up from original tweet
      - `:exclude_reply_user_ids` - Comma-separated list of user IDs to exclude from reply
      - `:attachment_url` - URL to associate with the tweet
      - `:media_ids` - List of media IDs to attach (up to 4)
      - `:possibly_sensitive` - Whether media might be sensitive
      - `:lat` - Latitude for geo-tagged tweet
      - `:long` - Longitude for geo-tagged tweet
      - `:place_id` - A place in the world
      - `:display_coordinates` - Whether to display coordinates
      - `:trim_user` - When true, only user ID will be returned
      - `:enable_dmcommands` - Enable DM deep linking
      - `:fail_dmcommands` - Fail if DM deep linking fails
      - `:card_uri` - Associate a card with the tweet

  ## Examples

      # Simple tweet
      {:ok, tweet} = XClient.Tweets.update("Hello, X!")

      # Tweet with media
      {:ok, media} = XClient.Media.upload("image.jpg")
      {:ok, tweet} = XClient.Tweets.update("Check this out!", media_ids: [media["media_id_string"]])

      # Reply to a tweet
      {:ok, reply} = XClient.Tweets.update(
        "@username Thanks!",
        in_reply_to_status_id: "123456789"
      )

  ## Rate Limit

  300 requests per 3 hours (combined with retweets)
  """
  def update(status, opts \\ [], client \\ nil)

  def update(status, opts, client) when is_binary(status) do
    params =
      opts
      |> Keyword.put(:status, status)
      |> build_params()

    HTTP.post("statuses/update.json", params, client)
  end

  def update(client, status, opts) when is_map(client) do
    update(status, opts, client)
  end

  @doc """
  Deletes a tweet.

  ## Parameters

    - `id` - The ID of the tweet to delete
    - `opts` - Optional parameters
      - `:trim_user` - When true, only user ID will be returned

  ## Examples

      {:ok, tweet} = XClient.Tweets.destroy("123456789")

  ## Returns

  The deleted tweet object.
  """
  def destroy(id, opts \\ [], client \\ nil) do
    params = build_params(opts)
    HTTP.post("statuses/destroy/#{id}.json", params, client)
  end

  @doc """
  Retweets a tweet.

  ## Parameters

    - `id` - The ID of the tweet to retweet
    - `opts` - Optional parameters
      - `:trim_user` - When true, only user ID will be returned

  ## Examples

      {:ok, tweet} = XClient.Tweets.retweet("123456789")

  ## Rate Limit

  300 requests per 3 hours (combined with tweet updates)
  """
  def retweet(id, opts \\ [], client \\ nil) do
    params = build_params(opts)
    HTTP.post("statuses/retweet/#{id}.json", params, client)
  end

  @doc """
  Unretweets a retweeted status.

  ## Parameters

    - `id` - The ID of the retweeted status
    - `opts` - Optional parameters
      - `:trim_user` - When true, only user ID will be returned

  ## Examples

      {:ok, tweet} = XClient.Tweets.unretweet("123456789")
  """
  def unretweet(id, opts \\ [], client \\ nil) do
    params = build_params(opts)
    HTTP.post("statuses/unretweet/#{id}.json", params, client)
  end

  @doc """
  Gets a single tweet by ID.

  ## Parameters

    - `id` - The ID of the tweet
    - `opts` - Optional parameters
      - `:trim_user` - When true, only user ID will be returned
      - `:include_my_retweet` - Include current user's retweet ID
      - `:include_entities` - Include entities node
      - `:include_ext_alt_text` - Include alt text for media
      - `:include_card_uri` - Include card URI

  ## Examples

      {:ok, tweet} = XClient.Tweets.show("123456789")

  ## Rate Limit

  900 requests per 15 minutes
  """
  def show(id, opts \\ [], client \\ nil) do
    params =
      opts
      |> Keyword.put(:id, id)
      |> build_params()

    HTTP.get("statuses/show.json", params, client)
  end

  @doc """
  Looks up multiple tweets by IDs.

  ## Parameters

    - `ids` - List of tweet IDs (up to 100)
    - `opts` - Optional parameters
      - `:include_entities` - Include entities node
      - `:trim_user` - When true, only user ID will be returned
      - `:map` - Return tweets in a map keyed by ID
      - `:include_ext_alt_text` - Include alt text for media
      - `:include_card_uri` - Include card URI

  ## Examples

      {:ok, tweets} = XClient.Tweets.lookup(["123", "456", "789"])

  ## Rate Limit

  900 requests per 15 minutes (user), 300 per 15 minutes (app)
  """
  def lookup(ids, opts \\ [], client \\ nil) when is_list(ids) do
    params =
      opts
      |> Keyword.put(:id, Enum.join(ids, ","))
      |> build_params()

    HTTP.post("statuses/lookup.json", params, client)
  end

  @doc """
  Returns the most recent tweets from a user's timeline.

  ## Parameters

    - `opts` - Optional parameters
      - `:user_id` - The ID of the user
      - `:screen_name` - The screen name of the user
      - `:since_id` - Returns results with ID greater than this
      - `:count` - Number of tweets to return (max 200)
      - `:max_id` - Returns results with ID less than or equal to this
      - `:trim_user` - When true, only user ID will be returned
      - `:exclude_replies` - Exclude replies
      - `:include_rts` - Include retweets

  ## Examples

      {:ok, tweets} = XClient.Tweets.user_timeline(screen_name: "elixirlang", count: 50)
      {:ok, tweets} = XClient.Tweets.user_timeline(user_id: "123456", count: 100)

  ## Rate Limit

  900 requests per 15 minutes (user), 1500 per 15 minutes (app)
  """
  def user_timeline(opts \\ [], client \\ nil) do
    params = build_params(opts)
    HTTP.get("statuses/user_timeline.json", params, client)
  end

  @doc """
  Returns the most recent mentions for the authenticating user.

  ## Parameters

    - `opts` - Optional parameters
      - `:count` - Number of tweets to return (max 200)
      - `:since_id` - Returns results with ID greater than this
      - `:max_id` - Returns results with ID less than or equal to this
      - `:trim_user` - When true, only user ID will be returned
      - `:include_entities` - Include entities node

  ## Examples

      {:ok, mentions} = XClient.Tweets.mentions_timeline(count: 100)

  ## Rate Limit

  75 requests per 15 minutes (user only)
  """
  def mentions_timeline(opts \\ [], client \\ nil) do
    params = build_params(opts)
    HTTP.get("statuses/mentions_timeline.json", params, client)
  end

  @doc """
  Returns the most recent tweets authored by the authenticating user that have been retweeted.

  ## Parameters

    - `opts` - Optional parameters
      - `:count` - Number of tweets to return (max 100)
      - `:since_id` - Returns results with ID greater than this
      - `:max_id` - Returns results with ID less than or equal to this
      - `:trim_user` - When true, only user ID will be returned
      - `:include_entities` - Include entities node
      - `:include_user_entities` - Include user entities

  ## Examples

      {:ok, tweets} = XClient.Tweets.retweets_of_me(count: 50)

  ## Rate Limit

  75 requests per 15 minutes (user only)
  """
  def retweets_of_me(opts \\ [], client \\ nil) do
    params = build_params(opts)
    HTTP.get("statuses/retweets_of_me.json", params, client)
  end

  @doc """
  Returns up to 100 of the first retweets of a given tweet.

  ## Parameters

    - `id` - The ID of the tweet
    - `opts` - Optional parameters
      - `:count` - Number of retweets to return (max 100)
      - `:trim_user` - When true, only user ID will be returned

  ## Examples

      {:ok, retweets} = XClient.Tweets.retweets("123456789", count: 50)

  ## Rate Limit

  75 requests per 15 minutes (user), 300 per 15 minutes (app)
  """
  def retweets(id, opts \\ [], client \\ nil) do
    params = build_params(opts)
    HTTP.get("statuses/retweets/#{id}.json", params, client)
  end

  @doc """
  Returns a collection of up to 100 user IDs who retweeted the tweet.

  ## Parameters

    - `id` - The ID of the tweet
    - `opts` - Optional parameters
      - `:count` - Number of IDs to return (max 100)
      - `:cursor` - Cursor for pagination
      - `:stringify_ids` - Return IDs as strings

  ## Examples

      {:ok, result} = XClient.Tweets.retweeters_ids("123456789")

  ## Rate Limit

  75 requests per 15 minutes (user), 300 per 15 minutes (app)
  """
  def retweeters_ids(id, opts \\ [], client \\ nil) do
    params =
      opts
      |> Keyword.put(:id, id)
      |> build_params()

    HTTP.get("statuses/retweeters/ids.json", params, client)
  end

  # Helper functions

  defp build_params(opts) do
    opts
    |> Enum.map(fn {k, v} -> {k, format_value(v)} end)
    |> Enum.into(%{})
  end

  defp format_value(value) when is_list(value), do: Enum.join(value, ",")
  defp format_value(value) when is_boolean(value), do: to_string(value)
  defp format_value(value), do: value
end
