defmodule XClient.Trends do
  @moduledoc """
  Trends operations for X API v1.1.

  ## Rate Limits

  - GET trends/place: 75 per 15 minutes
  - GET trends/available: 75 per 15 minutes
  - GET trends/closest: 75 per 15 minutes
  """

  alias XClient.HTTP

  @doc """
  Returns the trending topics for a specific WOEID.

  ## Parameters

    - `id` - The WOEID (Where On Earth ID) of the location
    - `opts` - Optional parameters
      - `:exclude` - Exclude hashtags from results

  ## Examples

      # Worldwide trends
      {:ok, trends} = XClient.Trends.place(1)

      # United States trends
      {:ok, trends} = XClient.Trends.place(23424977)

      # New York trends
      {:ok, trends} = XClient.Trends.place(2459115)

  ## Rate Limit

  75 requests per 15 minutes

  ## Common WOEIDs

  - Worldwide: 1
  - United States: 23424977
  - United Kingdom: 23424975
  - Canada: 23424775
  - India: 23424848
  """
  def place(id, opts \\ [], client \\ nil) do
    params =
      opts
      |> Keyword.put(:id, id)
      |> build_params()

    HTTP.get("trends/place.json", params, client)
  end

  @doc """
  Returns all available trend locations.

  ## Examples

      {:ok, locations} = XClient.Trends.available()

  ## Rate Limit

  75 requests per 15 minutes
  """
  def available(client \\ nil) do
    HTTP.get("trends/available.json", [], client)
  end

  @doc """
  Returns the locations that X has trending topic information for, closest to a specified location.

  ## Parameters

    - `opts` - Required parameters
      - `:lat` - Latitude
      - `:long` - Longitude

  ## Examples

      {:ok, locations} = XClient.Trends.closest(lat: 37.781157, long: -122.398720)

  ## Rate Limit

  75 requests per 15 minutes
  """
  def closest(opts \\ [], client \\ nil) do
    params = build_params(opts)
    HTTP.get("trends/closest.json", params, client)
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

defmodule XClient.Geo do
  @moduledoc """
  Geo operations for X API v1.1.

  ## Rate Limits

  - GET geo/id/:place_id: 75 per 15 minutes (user only)
  """

  alias XClient.HTTP

  @doc """
  Returns information about a place.

  ## Parameters

    - `place_id` - The place ID

  ## Examples

      {:ok, place} = XClient.Geo.id("df51dec6f4ee2b2c")

  ## Rate Limit

  75 requests per 15 minutes (user only)
  """
  def id(place_id, client \\ nil) do
    HTTP.get("geo/id/#{place_id}.json", [], client)
  end
end
