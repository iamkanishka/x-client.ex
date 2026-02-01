defmodule XClient.Lists do
  @moduledoc """
  Lists operations for X API v1.1.

  ## Rate Limits

  - GET lists/list: 15 per 15 minutes
  - GET lists/statuses: 900 per 15 minutes
  - GET lists/members: 900 per 15 minutes (user), 75 per 15 minutes (app)
  - GET lists/members/show: 15 per 15 minutes
  - GET lists/memberships: 75 per 15 minutes
  - GET lists/ownerships: 15 per 15 minutes
  - GET lists/show: 75 per 15 minutes
  - GET lists/subscribers: 180 per 15 minutes (user), 15 per 15 minutes (app)
  - GET lists/subscribers/show: 15 per 15 minutes
  - GET lists/subscriptions: 15 per 15 minutes
  """

  alias XClient.HTTP

  @doc """
  Returns all lists the authenticated user subscribes to, including their own.

  ## Parameters

    - `opts` - Optional parameters
      - `:user_id` - The ID of the user
      - `:screen_name` - The screen name of the user
      - `:reverse` - Return lists in reverse chronological order

  ## Examples

      {:ok, lists} = XClient.Lists.list()
      {:ok, lists} = XClient.Lists.list(screen_name: "elixirlang")

  ## Rate Limit

  15 requests per 15 minutes
  """
  def list(opts \\ [], client \\ nil) do
    params = build_params(opts)
    HTTP.get("lists/list.json", params, client)
  end

  @doc """
  Returns tweets from a specified list.

  ## Parameters

    - `opts` - Required parameters (one of):
      - `:list_id` - The numerical ID of the list
      - `:slug` and `:owner_screen_name` - List slug and owner
      - `:slug` and `:owner_id` - List slug and owner ID
    - Additional optional parameters:
      - `:since_id` - Returns results with ID greater than this
      - `:max_id` - Returns results with ID less than or equal to this
      - `:count` - Number of tweets to return (max 200)
      - `:include_entities` - Include entities node
      - `:include_rts` - Include retweets

  ## Examples

      {:ok, tweets} = XClient.Lists.statuses(list_id: "123456")
      {:ok, tweets} = XClient.Lists.statuses(
        slug: "team",
        owner_screen_name: "x"
      )

  ## Rate Limit

  900 requests per 15 minutes
  """
  def statuses(opts \\ [], client \\ nil) do
    params = build_params(opts)
    HTTP.get("lists/statuses.json", params, client)
  end

  @doc """
  Returns information about a list.

  ## Parameters

    - `opts` - Required parameters (one of):
      - `:list_id` - The numerical ID of the list
      - `:slug` and `:owner_screen_name` - List slug and owner
      - `:slug` and `:owner_id` - List slug and owner ID

  ## Examples

      {:ok, list} = XClient.Lists.show(list_id: "123456")

  ## Rate Limit

  75 requests per 15 minutes
  """
  def show(opts \\ [], client \\ nil) do
    params = build_params(opts)
    HTTP.get("lists/show.json", params, client)
  end

  @doc """
  Returns members of a specified list.

  ## Parameters

    - `opts` - Required parameters (one of):
      - `:list_id` - The numerical ID of the list
      - `:slug` and `:owner_screen_name` - List slug and owner
      - `:slug` and `:owner_id` - List slug and owner ID
    - Additional optional parameters:
      - `:count` - Number of members to return (max 5000)
      - `:cursor` - Cursor for pagination
      - `:include_entities` - Include entities node
      - `:skip_status` - Exclude status from user objects

  ## Examples

      {:ok, members} = XClient.Lists.members(list_id: "123456")

  ## Rate Limit

  900 requests per 15 minutes (user), 75 per 15 minutes (app)
  """
  def members(opts \\ [], client \\ nil) do
    params = build_params(opts)
    HTTP.get("lists/members.json", params, client)
  end

  @doc """
  Checks if a user is a member of a list.

  ## Parameters

    - `opts` - Required parameters:
      - List (one of):
        - `:list_id` - The numerical ID of the list
        - `:slug` and `:owner_screen_name` - List slug and owner
        - `:slug` and `:owner_id` - List slug and owner ID
      - User (one of):
        - `:user_id` - The ID of the user
        - `:screen_name` - The screen name of the user

  ## Examples

      {:ok, user} = XClient.Lists.members_show(
        list_id: "123456",
        screen_name: "elixirlang"
      )

  ## Rate Limit

  15 requests per 15 minutes
  """
  def members_show(opts \\ [], client \\ nil) do
    params = build_params(opts)
    HTTP.get("lists/members/show.json", params, client)
  end

  @doc """
  Returns lists the specified user is a member of.

  ## Parameters

    - `opts` - Optional parameters
      - `:user_id` - The ID of the user
      - `:screen_name` - The screen name of the user
      - `:count` - Number of lists to return (max 1000)
      - `:cursor` - Cursor for pagination
      - `:filter_to_owned_lists` - Only return lists user owns

  ## Examples

      {:ok, lists} = XClient.Lists.memberships(screen_name: "elixirlang")

  ## Rate Limit

  75 requests per 15 minutes
  """
  def memberships(opts \\ [], client \\ nil) do
    params = build_params(opts)
    HTTP.get("lists/memberships.json", params, client)
  end

  @doc """
  Returns lists owned by the specified user.

  ## Parameters

    - `opts` - Optional parameters
      - `:user_id` - The ID of the user
      - `:screen_name` - The screen name of the user
      - `:count` - Number of lists to return (max 1000)
      - `:cursor` - Cursor for pagination

  ## Examples

      {:ok, lists} = XClient.Lists.ownerships(screen_name: "x")

  ## Rate Limit

  15 requests per 15 minutes
  """
  def ownerships(opts \\ [], client \\ nil) do
    params = build_params(opts)
    HTTP.get("lists/ownerships.json", params, client)
  end

  @doc """
  Returns subscribers of a specified list.

  ## Parameters

    - `opts` - Required parameters (one of):
      - `:list_id` - The numerical ID of the list
      - `:slug` and `:owner_screen_name` - List slug and owner
      - `:slug` and `:owner_id` - List slug and owner ID
    - Additional optional parameters:
      - `:count` - Number of subscribers to return (max 5000)
      - `:cursor` - Cursor for pagination
      - `:include_entities` - Include entities node
      - `:skip_status` - Exclude status from user objects

  ## Examples

      {:ok, subscribers} = XClient.Lists.subscribers(list_id: "123456")

  ## Rate Limit

  180 requests per 15 minutes (user), 15 per 15 minutes (app)
  """
  def subscribers(opts \\ [], client \\ nil) do
    params = build_params(opts)
    HTTP.get("lists/subscribers.json", params, client)
  end

  @doc """
  Checks if a user is a subscriber of a list.

  ## Parameters

    - `opts` - Required parameters:
      - List (one of):
        - `:list_id` - The numerical ID of the list
        - `:slug` and `:owner_screen_name` - List slug and owner
        - `:slug` and `:owner_id` - List slug and owner ID
      - User (one of):
        - `:user_id` - The ID of the user
        - `:screen_name` - The screen name of the user

  ## Examples

      {:ok, user} = XClient.Lists.subscribers_show(
        list_id: "123456",
        screen_name: "elixirlang"
      )

  ## Rate Limit

  15 requests per 15 minutes
  """
  def subscribers_show(opts \\ [], client \\ nil) do
    params = build_params(opts)
    HTTP.get("lists/subscribers/show.json", params, client)
  end

  @doc """
  Returns lists the specified user is subscribed to.

  ## Parameters

    - `opts` - Optional parameters
      - `:user_id` - The ID of the user
      - `:screen_name` - The screen name of the user
      - `:count` - Number of lists to return (max 1000)
      - `:cursor` - Cursor for pagination

  ## Examples

      {:ok, lists} = XClient.Lists.subscriptions(screen_name: "elixirlang")

  ## Rate Limit

  15 requests per 15 minutes
  """
  def subscriptions(opts \\ [], client \\ nil) do
    params = build_params(opts)
    HTTP.get("lists/subscriptions.json", params, client)
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
