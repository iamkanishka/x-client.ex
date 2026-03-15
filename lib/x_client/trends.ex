defmodule XClient.Trends do
  @moduledoc """
  Trending topics — X API v1.1 `trends/*`.

  ## Rate Limits

  | Endpoint           | User auth   | App-only   |
  |--------------------|-------------|------------|
  | GET trends/place   | 75 / 15 min | 75 / 15 min|
  | GET trends/available | 75 / 15 min | 75 / 15 min|
  | GET trends/closest | 75 / 15 min | 75 / 15 min|

  ## Common WOEIDs

  | Location       | WOEID    |
  |----------------|----------|
  | Worldwide      | 1        |
  | United States  | 23424977 |
  | United Kingdom | 23424975 |
  | Canada         | 23424775 |
  | Australia      | 23424748 |
  | India          | 23424848 |
  | Germany        | 23424829 |
  | France         | 23424819 |
  | Japan          | 23424856 |
  | Brazil         | 23424768 |
  """

  alias XClient.{Client, HTTP, Params}

  @type response :: {:ok, list(map()) | map()} | {:error, XClient.Error.t()}

  @doc """
  Returns the top trending topics for a location identified by a WOEID.

  Returns a list with a single object containing the `trends` array and
  `as_of` / `created_at` / `locations` metadata.

  ## Parameters

    - `id` – WOEID (integer or string)

  ## Options

    - `:exclude` – Pass `"hashtags"` to remove hashtag trends from results

  ## Examples

      # Worldwide
      {:ok, [%{"trends" => trends}]} = XClient.Trends.place(1)

      # US, without hashtags
      {:ok, [%{"trends" => trends}]} = XClient.Trends.place(23424977, exclude: "hashtags")
  """
  @spec place(integer() | String.t(), keyword(), Client.t() | nil) :: response()
  def place(id, opts \\ [], client \\ nil) do
    params = Params.build(opts, id: id)
    HTTP.get("trends/place.json", params, client)
  end

  @doc """
  Returns all locations that X has trending topic information for.

  The response can be used to find WOEIDs for `place/3`.

  ## Example

      {:ok, locations} = XClient.Trends.available()
      # [{%{"name" => "Worldwide", "woeid" => 1, ...}}, ...]
  """
  @spec available(Client.t() | nil) :: response()
  def available(client \\ nil) do
    HTTP.get("trends/available.json", [], client)
  end

  @doc """
  Returns the locations with trending topic data closest to the provided coordinates.

  ## Options

    - `:lat` – Latitude (required)
    - `:long` – Longitude (required)

  ## Example

      {:ok, locations} = XClient.Trends.closest(lat: 37.781157, long: -122.398720)
  """
  @spec closest(keyword(), Client.t() | nil) :: response()
  def closest(opts \\ [], client \\ nil) do
    params = Params.build(opts)
    HTTP.get("trends/closest.json", params, client)
  end
end
