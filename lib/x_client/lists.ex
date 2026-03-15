defmodule XClient.Lists do
  @moduledoc """
  X List operations — X API v1.1 `lists/*`.

  ## Rate Limits

  | Endpoint                  | User auth    | App-only    |
  |---------------------------|--------------|-------------|
  | GET lists/list            | 15 / 15 min  | 15 / 15 min |
  | GET lists/statuses        | 900 / 15 min | —           |
  | GET lists/show            | 75 / 15 min  | —           |
  | GET lists/members         | 900 / 15 min | 75 / 15 min |
  | GET lists/members/show    | 15 / 15 min  | —           |
  | GET lists/memberships     | 75 / 15 min  | —           |
  | GET lists/ownerships      | 15 / 15 min  | —           |
  | GET lists/subscribers     | 180 / 15 min | 15 / 15 min |
  | GET lists/subscribers/show| 15 / 15 min  | —           |
  | GET lists/subscriptions   | 15 / 15 min  | —           |

  ## List Identification

  Many endpoints require a list to be identified by **one** of:
  - `:list_id` – numerical ID string
  - `slug:` + `:owner_screen_name`
  - `slug:` + `:owner_id`
  """

  alias XClient.{Client, HTTP, Params}

  @type response :: {:ok, map() | list()} | {:error, XClient.Error.t()}

  @doc """
  Returns all lists the authenticated user subscribes to, including their own.

  ## Options

    - `:user_id` / `:screen_name` – show lists for another user
    - `:reverse` – return in reverse chronological order

  ## Example

      {:ok, lists} = XClient.Lists.list()
      {:ok, lists} = XClient.Lists.list(screen_name: "elixirlang")
  """
  @spec list(keyword(), Client.t() | nil) :: response()
  def list(opts \\ [], client \\ nil) do
    HTTP.get("lists/list.json", Params.build(opts), client)
  end

  @doc """
  Returns recent tweets from the specified list.

  ## Options

    - `:list_id` / `:slug` + `:owner_screen_name` or `:owner_id` – identify the list
    - `:since_id` / `:max_id` – pagination
    - `:count` – max 200
    - `:include_entities` – include entities
    - `:include_rts` – include retweets
    - `:tweet_mode` – `"extended"` for full text

  ## Example

      {:ok, tweets} = XClient.Lists.statuses(list_id: "123456", count: 50)
  """
  @spec statuses(keyword(), Client.t() | nil) :: response()
  def statuses(opts \\ [], client \\ nil) do
    HTTP.get("lists/statuses.json", Params.build(opts), client)
  end

  @doc """
  Returns information about the specified list.

  ## Options

    - `:list_id` / `:slug` + `:owner_screen_name` or `:owner_id`

  ## Example

      {:ok, list} = XClient.Lists.show(list_id: "123456")
  """
  @spec show(keyword(), Client.t() | nil) :: response()
  def show(opts \\ [], client \\ nil) do
    HTTP.get("lists/show.json", Params.build(opts), client)
  end

  @doc """
  Returns members of the specified list (cursor-paginated).

  ## Options

    - `:list_id` / `:slug` + `:owner_screen_name` or `:owner_id`
    - `:count` – max 5000
    - `:cursor` – pagination cursor (-1 for first page)
    - `:include_entities` / `:skip_status`

  ## Example

      {:ok, %{"users" => members, "next_cursor" => cursor}} =
        XClient.Lists.members(list_id: "123456")
  """
  @spec members(keyword(), Client.t() | nil) :: response()
  def members(opts \\ [], client \\ nil) do
    HTTP.get("lists/members.json", Params.build(opts), client)
  end

  @doc """
  Returns the specified user if they are a member of the list, 404 error otherwise.

  Useful as a membership check.

  ## Options

    - List identification: `:list_id` / `:slug` + owner
    - User identification: `:user_id` or `:screen_name`
    - `:include_entities` / `:skip_status`

  ## Example

      {:ok, user} = XClient.Lists.members_show(
        list_id: "123456",
        screen_name: "elixirlang"
      )
  """
  @spec members_show(keyword(), Client.t() | nil) :: response()
  def members_show(opts \\ [], client \\ nil) do
    HTTP.get("lists/members/show.json", Params.build(opts), client)
  end

  @doc """
  Returns lists the specified user is a member of (cursor-paginated).

  ## Options

    - `:user_id` / `:screen_name`
    - `:count` – max 1000
    - `:cursor`
    - `:filter_to_owned_lists` – only return lists owned by the specified user

  ## Example

      {:ok, %{"lists" => lists}} = XClient.Lists.memberships(screen_name: "elixirlang")
  """
  @spec memberships(keyword(), Client.t() | nil) :: response()
  def memberships(opts \\ [], client \\ nil) do
    HTTP.get("lists/memberships.json", Params.build(opts), client)
  end

  @doc """
  Returns lists owned by the specified user (cursor-paginated).

  ## Options

    - `:user_id` / `:screen_name`
    - `:count` – max 1000
    - `:cursor`

  ## Example

      {:ok, %{"lists" => lists}} = XClient.Lists.ownerships(screen_name: "elixirlang")
  """
  @spec ownerships(keyword(), Client.t() | nil) :: response()
  def ownerships(opts \\ [], client \\ nil) do
    HTTP.get("lists/ownerships.json", Params.build(opts), client)
  end

  @doc """
  Returns subscribers of the specified list (cursor-paginated).

  ## Options

    - List identification: `:list_id` / `:slug` + owner
    - `:count` – max 5000
    - `:cursor`
    - `:include_entities` / `:skip_status`

  ## Example

      {:ok, %{"users" => subs}} = XClient.Lists.subscribers(list_id: "123456")
  """
  @spec subscribers(keyword(), Client.t() | nil) :: response()
  def subscribers(opts \\ [], client \\ nil) do
    HTTP.get("lists/subscribers.json", Params.build(opts), client)
  end

  @doc """
  Returns the specified user if they subscribe to the list, 404 otherwise.

  ## Options

    - List identification: `:list_id` / `:slug` + owner
    - User: `:user_id` / `:screen_name`

  ## Example

      {:ok, user} = XClient.Lists.subscribers_show(
        list_id: "123456",
        screen_name: "elixirlang"
      )
  """
  @spec subscribers_show(keyword(), Client.t() | nil) :: response()
  def subscribers_show(opts \\ [], client \\ nil) do
    HTTP.get("lists/subscribers/show.json", Params.build(opts), client)
  end

  @doc """
  Returns lists the specified user subscribes to (cursor-paginated).

  ## Options

    - `:user_id` / `:screen_name`
    - `:count` – max 1000
    - `:cursor`

  ## Example

      {:ok, %{"lists" => lists}} = XClient.Lists.subscriptions(screen_name: "elixirlang")
  """
  @spec subscriptions(keyword(), Client.t() | nil) :: response()
  def subscriptions(opts \\ [], client \\ nil) do
    HTTP.get("lists/subscriptions.json", Params.build(opts), client)
  end
end
