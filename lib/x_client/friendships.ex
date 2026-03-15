defmodule XClient.Friendships do
  @moduledoc """
  Follow / unfollow and relationship operations — X API v1.1 `friendships/*`, `followers/*`, `friends/*`.

  ## Rate Limits

  | Endpoint                 | User auth    | App-only    |
  |--------------------------|--------------|-------------|
  | POST friendships/create  | 400 / 24 h   | 1000 / 24 h |
  | POST friendships/destroy | —            | —           |
  | GET  friendships/show    | 180 / 15 min | 15 / 15 min |
  | GET  followers/ids       | 15 / 15 min  | 15 / 15 min |
  | GET  followers/list      | 15 / 15 min  | 15 / 15 min |
  | GET  friends/ids         | 15 / 15 min  | 15 / 15 min |
  | GET  friends/list        | 15 / 15 min  | 15 / 15 min |
  """

  alias XClient.{Client, HTTP, Params}

  @type response :: {:ok, term()} | {:error, XClient.Error.t()}

  @doc """
  Follows the user specified by `:user_id` or `:screen_name`.

  ## Options

    - `:user_id` or `:screen_name` (one required)
    - `:follow` – `true` to enable notifications for the target user

  ## Examples

      {:ok, user} = XClient.Friendships.create(screen_name: "elixirlang")
      {:ok, user} = XClient.Friendships.create(user_id: "123456")

  ## Rate Limit

  400 per 24 hours (user), 1000 per 24 hours (app-only).
  """
  @spec create(keyword(), Client.t() | nil) :: response()
  def create(opts \\ [], client \\ nil) do
    HTTP.post("friendships/create.json", Params.build(opts), client)
  end

  @doc """
  Unfollows the user specified by `:user_id` or `:screen_name`.

  ## Options

    - `:user_id` or `:screen_name` (one required)

  ## Examples

      {:ok, user} = XClient.Friendships.destroy(screen_name: "example")
      {:ok, user} = XClient.Friendships.destroy(user_id: "123456")
  """
  @spec destroy(keyword(), Client.t() | nil) :: response()
  def destroy(opts \\ [], client \\ nil) do
    HTTP.post("friendships/destroy.json", Params.build(opts), client)
  end

  @doc """
  Returns the relationship between two users.

  Requires **source** and **target** identification. At least one
  identifier per side is required.

  ## Options

    - Source: `:source_id` or `:source_screen_name`
    - Target: `:target_id` or `:target_screen_name`

  ## Example

      {:ok, %{"relationship" => rel}} = XClient.Friendships.show(
        source_screen_name: "josevalim",
        target_screen_name: "elixirlang"
      )

  ## Rate Limit

  180 per 15 minutes (user), 15 per 15 minutes (app-only).
  """
  @spec show(keyword(), Client.t() | nil) :: response()
  def show(opts \\ [], client \\ nil) do
    HTTP.get("friendships/show.json", Params.build(opts), client)
  end

  @doc """
  Returns a cursor-paginated list of user IDs **following** the given user.

  ## Options

    - `:user_id` / `:screen_name` – target user (defaults to authenticating user)
    - `:cursor` – pagination cursor (-1 for first page)
    - `:count` – max 5000 per page
    - `:stringify_ids` – return IDs as strings

  ## Example

      {:ok, %{"ids" => ids, "next_cursor" => cursor}} =
        XClient.Friendships.followers_ids(screen_name: "elixirlang")

  ## Rate Limit

  15 per 15 minutes.
  """
  @spec followers_ids(keyword(), Client.t() | nil) :: response()
  def followers_ids(opts \\ [], client \\ nil) do
    HTTP.get("followers/ids.json", Params.build(opts), client)
  end

  @doc """
  Returns a cursor-paginated list of user objects **following** the given user.

  ## Options

    - `:user_id` / `:screen_name`
    - `:cursor` – pagination cursor (-1 for first page)
    - `:count` – max 200 per page
    - `:skip_status` / `:include_user_entities`

  ## Example

      {:ok, %{"users" => users, "next_cursor" => cursor}} =
        XClient.Friendships.followers_list(screen_name: "elixirlang", count: 200)

  ## Rate Limit

  15 per 15 minutes.
  """
  @spec followers_list(keyword(), Client.t() | nil) :: response()
  def followers_list(opts \\ [], client \\ nil) do
    HTTP.get("followers/list.json", Params.build(opts), client)
  end

  @doc """
  Returns a cursor-paginated list of user IDs the given user **is following**.

  ## Options

    - `:user_id` / `:screen_name`
    - `:cursor` / `:count` / `:stringify_ids`

  ## Example

      {:ok, %{"ids" => ids}} = XClient.Friendships.friends_ids(screen_name: "elixirlang")

  ## Rate Limit

  15 per 15 minutes.
  """
  @spec friends_ids(keyword(), Client.t() | nil) :: response()
  def friends_ids(opts \\ [], client \\ nil) do
    HTTP.get("friends/ids.json", Params.build(opts), client)
  end

  @doc """
  Returns a cursor-paginated list of user objects the given user **is following**.

  ## Options

    - `:user_id` / `:screen_name`
    - `:cursor` / `:count` / `:skip_status` / `:include_user_entities`

  ## Example

      {:ok, %{"users" => users}} = XClient.Friendships.friends_list(screen_name: "elixirlang")

  ## Rate Limit

  15 per 15 minutes.
  """
  @spec friends_list(keyword(), Client.t() | nil) :: response()
  def friends_list(opts \\ [], client \\ nil) do
    HTTP.get("friends/list.json", Params.build(opts), client)
  end
end
