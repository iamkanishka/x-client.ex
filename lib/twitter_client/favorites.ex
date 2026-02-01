defmodule XClient.Favorites do
  @moduledoc """
  Favorites (likes) operations for X API v1.1.

  ## Rate Limits

  - POST favorites/create: 1000 per 24 hours
  - GET favorites/list: 75 per 15 minutes
  """

  alias XClient.HTTP

  @doc """
  Favorites (likes) a tweet.

  ## Parameters

    - `id` - The ID of the tweet to favorite
    - `opts` - Optional parameters
      - `:include_entities` - Include entities node

  ## Examples

      {:ok, tweet} = XClient.Favorites.create("123456789")

  ## Rate Limit

  1000 requests per 24 hours
  """
  def create(id, opts \\ [], client \\ nil) do
    params =
      opts
      |> Keyword.put(:id, id)
      |> build_params()

    HTTP.post("favorites/create.json", params, client)
  end

  @doc """
  Unfavorites (unlikes) a tweet.

  ## Parameters

    - `id` - The ID of the tweet to unfavorite
    - `opts` - Optional parameters
      - `:include_entities` - Include entities node

  ## Examples

      {:ok, tweet} = XClient.Favorites.destroy("123456789")
  """
  def destroy(id, opts \\ [], client \\ nil) do
    params =
      opts
      |> Keyword.put(:id, id)
      |> build_params()

    HTTP.post("favorites/destroy.json", params, client)
  end

  @doc """
  Returns the most recent tweets liked by the specified user.

  ## Parameters

    - `opts` - Optional parameters
      - `:user_id` - The ID of the user
      - `:screen_name` - The screen name of the user
      - `:count` - Number of tweets to return (max 200)
      - `:since_id` - Returns results with ID greater than this
      - `:max_id` - Returns results with ID less than or equal to this
      - `:include_entities` - Include entities node

  ## Examples

      {:ok, favorites} = XClient.Favorites.list(screen_name: "elixirlang")
      {:ok, favorites} = XClient.Favorites.list(user_id: "123456", count: 100)

  ## Rate Limit

  75 requests per 15 minutes
  """
  def list(opts \\ [], client \\ nil) do
    params = build_params(opts)
    HTTP.get("favorites/list.json", params, client)
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
