defmodule XClient.API do
  @moduledoc """
  Application-level rate limit introspection — X API v1.1 `application/*`.

  **Bug fix:** In the original codebase, `XClient.API` (rate limit status)
  was defined inside `test/test_helper.exs` and would never be compiled or
  available in production. It is now correctly placed in `lib/`.

  Note: The OTP application callback module is `XClient.Application` (separate).
  This module (`XClient.API`) is the X API application-level endpoint wrapper.

  ## Rate Limits

  | Endpoint                         | User auth    | App-only     |
  |----------------------------------|--------------|--------------|
  | GET application/rate_limit_status| 180 / 15 min | 180 / 15 min |
  """

  alias XClient.{Client, HTTP}

  @type response :: {:ok, term()} | {:error, XClient.Error.t()}

  @doc """
  Returns the current rate limit status for all or selected resource families.

  The response groups endpoints by resource family and shows `limit`,
  `remaining`, and `reset` (Unix timestamp) for each.

  ## Options

    - `:resources` – Comma-separated list of resource families to filter by.
      If omitted, all families are returned. Valid families include:
      `statuses`, `friends`, `followers`, `users`, `search`, `lists`,
      `direct_messages`, `favorites`, `trends`, `geo`, `account`,
      `application`, `help`

  ## Examples

      # All rate limits
      {:ok, %{"resources" => resources}} = XClient.API.rate_limit_status()

      # Check just statuses and friends
      {:ok, %{"resources" => resources}} =
        XClient.API.rate_limit_status(resources: "statuses,friends")

      # Inspect a specific endpoint
      resources["statuses"]["/statuses/user_timeline"]
      #=> %{"limit" => 900, "remaining" => 897, "reset" => 1712345678}

  ## Rate Limit

  180 per 15 minutes.
  """
  @spec rate_limit_status(keyword(), Client.t() | nil) :: response()
  def rate_limit_status(opts \\ [], client \\ nil) do
    params =
      case Keyword.get(opts, :resources) do
        nil -> %{}
        resources -> %{resources: resources}
      end

    HTTP.get("application/rate_limit_status.json", params, client)
  end
end
