defmodule XClient.Friendships do
  @moduledoc """
  Friendships (follow/unfollow) operations for X API v1.1.

  ## Rate Limits

  - POST friendships/create: 400 per 24 hours (user), 1000 per 24 hours (app)
  - GET friendships/show: 180 per 15 minutes (user), 15 per 15 minutes (app)
  - GET followers/ids: 15 per 15 minutes
  - GET followers/list: 15 per 15 minutes
  - GET friends/ids: 15 per 15 minutes
  - GET friends/list: 15 per 15 minutes
  """

  alias XClient.HTTP

  @doc """
  Follows a user.

  ## Parameters

    - `opts` - Required parameters (one of):
      - `:user_id` - The ID of the user to follow
      - `:screen_name` - The screen name of the user to follow
    - Additional optional parameters:
      - `:follow` - Enable notifications for the target user

  ## Examples

      {:ok, user} = XClient.Friendships.create(screen_name: "elixirlang")
      {:ok, user} = XClient.Friendships.create(user_id: "123456")

  ## Rate Limit

  400 requests per 24 hours (user), 1000 per 24 hours (app)
  """
  def create(opts \\ [], client \\ nil) do
    params = build_params(opts)
    HTTP.post("friendships/create.json", params, client)
  end

  @doc """
  Unfollows a user.

  ## Parameters

    - `opts` - Required parameters (one of):
      - `:user_id` - The ID of the user to unfollow
      - `:screen_name` - The screen name of the user to unfollow

  ## Examples

      {:ok, user} = XClient.Friendships.destroy(screen_name: "example")
      {:ok, user} = XClient.Friendships.destroy(user_id: "123456")
  """
  def destroy(opts \\ [], client \\ nil) do
    params = build_params(opts)
    HTTP.post("friendships/destroy.json", params, client)
  end

  @doc """
  Returns detailed information about the relationship between two users.

  ## Parameters

    - `opts` - Required parameters:
      - Source user (one of):
        - `:source_id` - The user ID of the subject user
        - `:source_screen_name` - The screen name of the subject user
      - Target user (one of):
        - `:target_id` - The user ID of the target user
        - `:target_screen_name` - The screen name of the target user

  ## Examples

      {:ok, relationship} = XClient.Friendships.show(
        source_screen_name: "user1",
        target_screen_name: "user2"
      )

  ## Rate Limit

  180 requests per 15 minutes (user), 15 per 15 minutes (app)
  """
  def show(opts \\ [], client \\ nil) do
    params = build_params(opts)
    HTTP.get("friendships/show.json", params, client)
  end

  @doc """
  Returns a collection of user IDs for users following the specified user.

  ## Parameters

    - `opts` - Optional parameters
      - `:user_id` - The ID of the user
      - `:screen_name` - The screen name of the user
      - `:cursor` - Cursor for pagination (-1 for first page)
      - `:count` - Number of IDs to return per page (max 5000)
      - `:stringify_ids` - Return IDs as strings

  ## Examples

      {:ok, result} = XClient.Friendships.followers_ids(screen_name: "elixirlang")
      {:ok, result} = XClient.Friendships.followers_ids(user_id: "123456", count: 5000)

  ## Rate Limit

  15 requests per 15 minutes
  """
  def followers_ids(opts \\ [], client \\ nil) do
    params = build_params(opts)
    HTTP.get("followers/ids.json", params, client)
  end

  @doc """
  Returns a collection of user objects for users following the specified user.

  ## Parameters

    - `opts` - Optional parameters
      - `:user_id` - The ID of the user
      - `:screen_name` - The screen name of the user
      - `:cursor` - Cursor for pagination (-1 for first page)
      - `:count` - Number of users to return per page (max 200)
      - `:skip_status` - Exclude status from user objects
      - `:include_user_entities` - Include user entities

  ## Examples

      {:ok, result} = XClient.Friendships.followers_list(screen_name: "elixirlang")

  ## Rate Limit

  15 requests per 15 minutes
  """
  def followers_list(opts \\ [], client \\ nil) do
    params = build_params(opts)
    HTTP.get("followers/list.json", params, client)
  end

  @doc """
  Returns a collection of user IDs for users the specified user is following.

  ## Parameters

    - `opts` - Optional parameters
      - `:user_id` - The ID of the user
      - `:screen_name` - The screen name of the user
      - `:cursor` - Cursor for pagination (-1 for first page)
      - `:count` - Number of IDs to return per page (max 5000)
      - `:stringify_ids` - Return IDs as strings

  ## Examples

      {:ok, result} = XClient.Friendships.friends_ids(screen_name: "elixirlang")

  ## Rate Limit

  15 requests per 15 minutes
  """
  def friends_ids(opts \\ [], client \\ nil) do
    params = build_params(opts)
    HTTP.get("friends/ids.json", params, client)
  end

  @doc """
  Returns a collection of user objects for users the specified user is following.

  ## Parameters

    - `opts` - Optional parameters
      - `:user_id` - The ID of the user
      - `:screen_name` - The screen name of the user
      - `:cursor` - Cursor for pagination (-1 for first page)
      - `:count` - Number of users to return per page (max 200)
      - `:skip_status` - Exclude status from user objects
      - `:include_user_entities` - Include user entities

  ## Examples

      {:ok, result} = XClient.Friendships.friends_list(screen_name: "elixirlang")

  ## Rate Limit

  15 requests per 15 minutes
  """
  def friends_list(opts \\ [], client \\ nil) do
    params = build_params(opts)
    HTTP.get("friends/list.json", params, client)
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
