defmodule XClient.Favorites do
  @moduledoc """
  Like / unlike operations — X API v1.1 `favorites/*`.

  ## Rate Limits

  | Endpoint              | User auth    | App-only |
  |-----------------------|--------------|----------|
  | POST favorites/create | 1000 / 24 h  | —        |
  | POST favorites/destroy| —            | —        |
  | GET  favorites/list   | 75 / 15 min  | —        |
  """

  alias XClient.{Client, HTTP, Params}

  @type response :: {:ok, term()} | {:error, XClient.Error.t()}
  @type list_response :: {:ok, term()} | {:error, XClient.Error.t()}

  @doc """
  Likes (favorites) a tweet.

  ## Parameters

    - `id` – The ID string of the tweet to like

  ## Options

    - `:include_entities` – include entities node in response

  ## Example

      {:ok, tweet} = XClient.Favorites.create("123456789")

  ## Rate Limit

  1000 per 24 hours.
  """
  @spec create(String.t(), keyword(), Client.t() | nil) :: response()
  def create(id, opts \\ [], client \\ nil) when is_binary(id) do
    params = Params.build(opts, id: id)
    HTTP.post("favorites/create.json", params, client)
  end

  @doc """
  Unlikes (unfavorites) a tweet.

  ## Parameters

    - `id` – The ID string of the tweet to unlike

  ## Options

    - `:include_entities` – include entities node

  ## Example

      {:ok, tweet} = XClient.Favorites.destroy("123456789")
  """
  @spec destroy(String.t(), keyword(), Client.t() | nil) :: response()
  def destroy(id, opts \\ [], client \\ nil) when is_binary(id) do
    params = Params.build(opts, id: id)
    HTTP.post("favorites/destroy.json", params, client)
  end

  @doc """
  Returns up to 200 of the most recent tweets liked by the specified user.

  ## Options

    - `:user_id` – target user ID
    - `:screen_name` – target user screen name
    - `:count` – number of tweets (max 200)
    - `:since_id` – return results newer than this ID
    - `:max_id` – return results at or older than this ID
    - `:include_entities` – include entities
    - `:tweet_mode` – `"extended"` for full text

  ## Examples

      {:ok, likes} = XClient.Favorites.list(screen_name: "elixirlang")
      {:ok, likes} = XClient.Favorites.list(user_id: "123456", count: 50)

  ## Rate Limit

  75 per 15 minutes (user auth only).
  """
  @spec list(keyword(), Client.t() | nil) :: list_response()
  def list(opts \\ [], client \\ nil) do
    params = Params.build(opts)
    HTTP.get("favorites/list.json", params, client)
  end
end
