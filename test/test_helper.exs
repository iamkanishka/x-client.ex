defmodule XClient.Help do
  @moduledoc """
  Help and configuration operations for X API v1.1.

  ## Rate Limits

  - GET help/configuration: 15 per 15 minutes
  - GET help/languages: 15 per 15 minutes
  - GET help/privacy: 15 per 15 minutes
  - GET help/tos: 15 per 15 minutes
  """

  alias XClient.HTTP

  @doc """
  Returns X's configuration information.

  ## Examples

      {:ok, config} = XClient.Help.configuration()

  ## Rate Limit

  15 requests per 15 minutes

  ## Returns

  Configuration details including:
  - characters_reserved_per_media
  - max_media_per_upload
  - non_username_paths
  - photo_size_limit
  - short_url_length
  - short_url_length_https
  """
  def configuration(client \\ nil) do
    HTTP.get("help/configuration.json", [], client)
  end

  @doc """
  Returns the list of languages supported by X.

  ## Examples

      {:ok, languages} = XClient.Help.languages()

  ## Rate Limit

  15 requests per 15 minutes

  ## Returns

  List of language objects with code, name, and status.
  """
  def languages(client \\ nil) do
    HTTP.get("help/languages.json", [], client)
  end

  @doc """
  Returns X's Privacy Policy.

  ## Examples

      {:ok, privacy} = XClient.Help.privacy()

  ## Rate Limit

  15 requests per 15 minutes
  """
  def privacy(client \\ nil) do
    HTTP.get("help/privacy.json", [], client)
  end

  @doc """
  Returns X's Terms of Service.

  ## Examples

      {:ok, tos} = XClient.Help.tos()

  ## Rate Limit

  15 requests per 15 minutes
  """
  def tos(client \\ nil) do
    HTTP.get("help/tos.json", [], client)
  end
end

defmodule XClient.API do
  @moduledoc """
  Application-level operations for X API v1.1.

  ## Rate Limits

  - GET application/rate_limit_status: 180 per 15 minutes
  """

  alias XClient.HTTP

  @doc """
  Returns the current rate limits for methods belonging to the specified resource families.

  ## Parameters

    - `opts` - Optional parameters
      - `:resources` - Comma-separated list of resource families (e.g., "statuses,friends,users")

  ## Examples

      # Get all rate limits
      {:ok, limits} = XClient.API.rate_limit_status()

      # Get specific rate limits
      {:ok, limits} = XClient.API.rate_limit_status(
        resources: "statuses,friends"
      )

  ## Rate Limit

  180 requests per 15 minutes

  ## Returns

  Rate limit status for each endpoint, including:
  - limit: The rate limit ceiling for that endpoint
  - remaining: Number of requests remaining in current window
  - reset: Unix timestamp when the rate limit window resets

  ## Resource Families

  - statuses
  - friends
  - followers
  - users
  - search
  - lists
  - direct_messages
  - favorites
  - trends
  - geo
  - account
  - application
  - help
  """
  def rate_limit_status(opts \\ [], client \\ nil) do
    params =
      case Keyword.get(opts, :resources) do
        nil -> %{}
        resources -> %{resources: resources}
      end

    HTTP.get("application/rate_limit_status.json", params, client)
  end
end
