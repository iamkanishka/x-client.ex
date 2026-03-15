defmodule XClient.Users do
  @moduledoc """
  User lookup and search operations — X API v1.1 `users/*`.

  ## Rate Limits

  | Endpoint                       | User auth    | App-only     |
  |--------------------------------|--------------|--------------|
  | GET users/show                 | 900 / 15 min | 900 / 15 min |
  | GET users/lookup               | 900 / 15 min | 300 / 15 min |
  | GET users/search               | 900 / 15 min | —            |
  | GET users/suggestions          | 15 / 15 min  | 15 / 15 min  |
  | GET users/suggestions/:slug    | 15 / 15 min  | 15 / 15 min  |
  """

  alias XClient.{Client, HTTP, Params}

  @type response :: {:ok, term()} | {:error, XClient.Error.t()}
  @type list_response :: {:ok, term()} | {:error, XClient.Error.t()}

  @doc """
  Returns public information about a single user.

  Requires either `:user_id` or `:screen_name`.

  ## Options

    - `:user_id` – the user's numeric ID
    - `:screen_name` – the user's screen name (without `@`)
    - `:include_entities` – include URL entities

  ## Example

      {:ok, user} = XClient.Users.show(screen_name: "elixirlang")
      {:ok, user} = XClient.Users.show(user_id: "1234567890")
  """
  @spec show(keyword(), Client.t() | nil) :: response()
  def show(opts \\ [], client \\ nil) do
    HTTP.get("users/show.json", Params.build(opts), client)
  end

  @doc """
  Returns fully-hydrated user objects for up to 100 users per request.

  Requires either `:user_id` or `:screen_name` (lists accepted).

  ## Example

      {:ok, users} = XClient.Users.lookup(screen_name: ["user1", "user2"])
      {:ok, users} = XClient.Users.lookup(user_id: ["111", "222"])
  """
  @spec lookup(keyword(), Client.t() | nil) :: list_response()
  def lookup(opts \\ [], client \\ nil) do
    HTTP.post("users/lookup.json", Params.build(opts), client)
  end

  @doc """
  Searches for users matching the given query (max 20 results per page).

  ## Options

    - `:page` – 1-based page number
    - `:count` – results per page (max 20)
    - `:include_entities` – include entities

  ## Example

      {:ok, users} = XClient.Users.search("elixir", count: 20)
  """
  @spec search(String.t(), keyword(), Client.t() | nil) :: list_response()
  def search(query, opts \\ [], client \\ nil) when is_binary(query) do
    HTTP.get("users/search.json", Params.build(opts, q: query), client)
  end

  @doc """
  Returns a list of suggested user categories (slugs).

  ## Options

    - `:lang` – ISO 639-1 language code

  ## Example

      {:ok, categories} = XClient.Users.suggestions(lang: "en")
  """
  @spec suggestions(keyword(), Client.t() | nil) :: list_response()
  def suggestions(opts \\ [], client \\ nil) do
    HTTP.get("users/suggestions.json", Params.build(opts), client)
  end

  @doc """
  Returns suggested users for a specific category slug.

  ## Example

      {:ok, suggestion} = XClient.Users.suggestions_slug("technology")
  """
  @spec suggestions_slug(String.t(), keyword(), Client.t() | nil) :: response()
  def suggestions_slug(slug, opts \\ [], client \\ nil) when is_binary(slug) do
    HTTP.get("users/suggestions/#{slug}.json", Params.build(opts), client)
  end

  @doc """
  Returns members of a suggested user category who have a verified account.

  ## Example

      {:ok, members} = XClient.Users.suggestions_members("technology")
  """
  @spec suggestions_members(String.t(), Client.t() | nil) :: list_response()
  def suggestions_members(slug, client \\ nil) when is_binary(slug) do
    HTTP.get("users/suggestions/#{slug}/members.json", %{}, client)
  end
end
