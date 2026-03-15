defmodule XClient.Search do
  @moduledoc """
  Tweet search — X API v1.1 `search/tweets`.

  ## Rate Limits

  | Endpoint       | User auth    | App-only     |
  |----------------|--------------|--------------|
  | GET search/tweets | 180 / 15 min | 450 / 15 min |

  ## Query Operators

  The `q` parameter supports X's search operators:

  | Operator              | Meaning                                  |
  |-----------------------|------------------------------------------|
  | `elixir lang`         | tweets containing both words             |
  | `"elixir lang"`       | exact phrase match                       |
  | `elixir OR phoenix`   | either word                              |
  | `elixir -rails`       | elixir but not rails                     |
  | `#myelixirstatus`     | containing a hashtag                     |
  | `from:josevalim`      | sent from a user                         |
  | `to:elixirlang`       | replies to a user                        |
  | `@elixirlang`         | mentioning a user                        |
  | `filter:links`        | containing URLs                          |
  | `since:2024-01-01`    | sent after date                          |
  | `until:2024-12-31`    | sent before date                         |
  | `geocode:lat,lng,r`   | within radius of a location              |
  """

  alias XClient.{Client, HTTP, Params}

  @type response :: {:ok, term()} | {:error, XClient.Error.t()}

  @doc """
  Searches for recent tweets matching the given query string.

  Returns up to 100 tweets per request. For iterative collection use
  `:since_id` and `:max_id` cursoring.

  ## Parameters

    - `query` – Search query (max 500 characters, URL-encoded automatically)

  ## Options

    - `:geocode` – `"lat,long,radius"` e.g. `"37.78,-122.39,5mi"`
    - `:lang` – ISO 639-1 language code to restrict results
    - `:locale` – Query locale (only `"ja"` is currently supported)
    - `:result_type` – `"mixed"` (default) | `"recent"` | `"popular"`
    - `:count` – Tweets per response (max 100, default 15)
    - `:until` – `"YYYY-MM-DD"` — return tweets before this date
    - `:since_id` – Return tweets newer than this ID
    - `:max_id` – Return tweets at or older than this ID
    - `:include_entities` – Include entities node
    - `:tweet_mode` – `"extended"` for full (> 140 char) text

  ## Examples

      {:ok, %{"statuses" => tweets, "search_metadata" => meta}} =
        XClient.Search.tweets("elixir lang", count: 100, result_type: "recent")

      # Geo-restricted
      {:ok, result} = XClient.Search.tweets("coffee",
        geocode: "37.781157,-122.398720,5mi",
        result_type: "recent"
      )

      # Pagination — walk backwards through results
      {:ok, %{"statuses" => first_page, "search_metadata" => %{"max_id" => max_id}}} =
        XClient.Search.tweets("#elixir", count: 100)

      {:ok, %{"statuses" => next_page}} =
        XClient.Search.tweets("#elixir", count: 100, max_id: max_id - 1)

  ## Rate Limit

  180 per 15 minutes (user auth), 450 per 15 minutes (app-only).
  """
  @spec tweets(String.t(), keyword(), Client.t() | nil) :: response()
  def tweets(query, opts \\ [], client \\ nil) when is_binary(query) do
    params = Params.build(opts, q: query)
    HTTP.get("search/tweets.json", params, client)
  end
end
