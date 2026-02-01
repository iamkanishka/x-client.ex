defmodule XClient.Users do
  @moduledoc """
  User operations for X API v1.1.

  ## Rate Limits

  - GET users/show: 900 per 15 minutes
  - GET users/lookup: 900 per 15 minutes (user), 300 per 15 minutes (app)
  - GET users/search: 900 per 15 minutes (user only)
  - GET users/suggestions: 15 per 15 minutes
  - GET users/suggestions/:slug: 15 per 15 minutes
  - GET users/suggestions/:slug/members: 15 per 15 minutes
  """

  alias XClient.HTTP

  @doc """
  Returns information about a single user.

  ## Parameters

    - `opts` - Required parameters (one of):
      - `:user_id` - The ID of the user
      - `:screen_name` - The screen name of the user
    - Additional optional parameters:
      - `:include_entities` - Include entities node

  ## Examples

      {:ok, user} = XClient.Users.show(screen_name: "elixirlang")
      {:ok, user} = XClient.Users.show(user_id: "123456")

  ## Rate Limit

  900 requests per 15 minutes
  """
  def show(opts \\ [], client \\ nil) do
    params = build_params(opts)
    HTTP.get("users/show.json", params, client)
  end

  @doc """
  Returns information about multiple users (up to 100).

  ## Parameters

    - `opts` - Required parameters (one of):
      - `:user_id` - List of user IDs or comma-separated string
      - `:screen_name` - List of screen names or comma-separated string
    - Additional optional parameters:
      - `:include_entities` - Include entities node
      - `:tweet_mode` - Use "extended" for full text

  ## Examples

      {:ok, users} = XClient.Users.lookup(screen_name: ["user1", "user2"])
      {:ok, users} = XClient.Users.lookup(user_id: ["123", "456"])

  ## Rate Limit

  900 requests per 15 minutes (user), 300 per 15 minutes (app)
  """
  def lookup(opts \\ [], client \\ nil) do
    params = build_params(opts)
    HTTP.post("users/lookup.json", params, client)
  end

  @doc """
  Searches for users matching a query.

  ## Parameters

    - `query` - The search query
    - `opts` - Optional parameters
      - `:page` - Page number (1-based)
      - `:count` - Number of users to return per page (max 20)
      - `:include_entities` - Include entities node

  ## Examples

      {:ok, users} = XClient.Users.search("elixir", count: 20)

  ## Rate Limit

  900 requests per 15 minutes (user only)
  """
  def search(query, opts \\ [], client \\ nil) do
    params =
      opts
      |> Keyword.put(:q, query)
      |> build_params()

    HTTP.get("users/search.json", params, client)
  end

  @doc """
  Returns suggested user categories.

  ## Parameters

    - `opts` - Optional parameters
      - `:lang` - Language code

  ## Examples

      {:ok, suggestions} = XClient.Users.suggestions()

  ## Rate Limit

  15 requests per 15 minutes
  """
  def suggestions(opts \\ [], client \\ nil) do
    params = build_params(opts)
    HTTP.get("users/suggestions.json", params, client)
  end

  @doc """
  Returns suggested users for a specific category.

  ## Parameters

    - `slug` - The category slug
    - `opts` - Optional parameters
      - `:lang` - Language code

  ## Examples

      {:ok, suggestion} = XClient.Users.suggestions_slug("technology")

  ## Rate Limit

  15 requests per 15 minutes
  """
  def suggestions_slug(slug, opts \\ [], client \\ nil) do
    params = build_params(opts)
    HTTP.get("users/suggestions/#{slug}.json", params, client)
  end

  @doc """
  Returns members of a suggested user category.

  ## Parameters

    - `slug` - The category slug

  ## Examples

      {:ok, members} = XClient.Users.suggestions_members("technology")

  ## Rate Limit

  15 requests per 15 minutes
  """
  def suggestions_members(slug, client \\ nil) do
    HTTP.get("users/suggestions/#{slug}/members.json", [], client)
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
