defmodule XClient.Search do
  @moduledoc """
  Search operations for X API v1.1.

  ## Rate Limits

  - GET search/tweets: 180 per 15 minutes (user), 450 per 15 minutes (app)
  """

  alias XClient.HTTP

  @doc """
  Searches for tweets matching a query.

  ## Parameters

    - `query` - The search query string
    - `opts` - Optional parameters
      - `:geocode` - Returns tweets by users located within radius of lat,long (e.g., "37.781157,-122.398720,1mi")
      - `:lang` - Restricts tweets to the given language (ISO 639-1 code)
      - `:locale` - Language of the query (only ja is currently supported)
      - `:result_type` - Type of results (mixed, recent, popular)
      - `:count` - Number of tweets to return (max 100)
      - `:until` - Returns tweets created before the given date (YYYY-MM-DD)
      - `:since_id` - Returns results with ID greater than this
      - `:max_id` - Returns results with ID less than or equal to this
      - `:include_entities` - Include entities node

  ## Examples

      {:ok, results} = XClient.Search.tweets("elixir lang", count: 100)

      {:ok, results} = XClient.Search.tweets(
        "coffee",
        geocode: "37.781157,-122.398720,5mi",
        result_type: "recent"
      )

  ## Rate Limit

  180 requests per 15 minutes (user), 450 per 15 minutes (app)

  ## Query Operators

  You can use various operators in your search query:

  - `watching now` - containing both "watching" and "now"
  - `"happy hour"` - exact phrase
  - `love OR hate` - containing either "love" or "hate"
  - `beer -root` - containing "beer" but not "root"
  - `#haiku` - containing the hashtag "haiku"
  - `from:alexiskold` - sent from person "alexiskold"
  - `to:techcrunch` - sent to person "techcrunch"
  - `@mashable` - referencing person "mashable"
  - `superhero since:2015-12-21` - containing "superhero" and sent since date
  - `ftw until:2015-12-21` - containing "ftw" and sent before date
  - `movie -scary :)` - containing "movie", not "scary", with positive attitude
  - `flight :(` - containing "flight" with negative attitude
  - `traffic ?` - containing "traffic" and asking a question
  - `hilarious filter:links` - containing "hilarious" and linking to URLs
  """
  def tweets(query, opts \\ [], client \\ nil) do
    params =
      opts
      |> Keyword.put(:q, query)
      |> build_params()

    HTTP.get("search/tweets.json", params, client)
  end

  # Helper functions

  defp build_params(opts) do
    opts
    |> Enum.map(fn {k, v} -> {k, format_value(v)} end)
    |> Enum.into(%{})
  end

  defp format_value(value) when is_boolean(value), do: to_string(value)
  defp format_value(value), do: value
end
