defmodule XClient.Geo do
  @moduledoc """
  Geographic place lookup — X API v1.1 `geo/*`.

  **Bug fix:** In the original codebase, `XClient.Geo` was appended at the
  bottom of `trends.ex`. It is now correctly in its own file.

  ## Rate Limits

  | Endpoint       | User auth   | App-only |
  |----------------|-------------|----------|
  | GET geo/id/:id | 75 / 15 min | —        |
  """

  alias XClient.{Client, HTTP}

  @type response :: {:ok, term()} | {:error, XClient.Error.t()}

  @doc """
  Returns all the information about a known place.

  Place IDs are returned by many X endpoints (e.g., tweet `place` fields).

  ## Parameters

    - `place_id` – The alphanumeric X Place ID string

  ## Example

      {:ok, place} = XClient.Geo.id("df51dec6f4ee2b2c")
      # %{"full_name" => "Manhattan, NY", "country" => "United States", ...}

  ## Rate Limit

  75 per 15 minutes (user auth only).
  """
  @spec id(String.t(), Client.t() | nil) :: response()
  def id(place_id, client \\ nil) when is_binary(place_id) do
    HTTP.get("geo/id/#{place_id}.json", [], client)
  end
end
