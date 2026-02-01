defmodule XClient.Error do
  @moduledoc """
  Error struct for X API errors.
  """

  defexception [:status, :message, :code, :rate_limit_info]

  @type t :: %__MODULE__{
          status: integer() | nil,
          message: String.t(),
          code: integer() | nil,
          rate_limit_info: map() | nil
        }

  def message(%__MODULE__{status: status, message: message, code: code}) do
    parts = []

    parts = if status, do: ["Status: #{status}" | parts], else: parts
    parts = if code, do: ["Code: #{code}" | parts], else: parts
    parts = [message | parts]

    Enum.join(parts, " - ")
  end

  @doc """
  Creates an error from a rate limit response.
  """
  def rate_limited(rate_limit_info) do
    reset_time =
      case rate_limit_info[:reset] do
        nil -> "unknown"
        timestamp -> DateTime.from_unix!(timestamp) |> DateTime.to_string()
      end

    %__MODULE__{
      status: 429,
      message: "Rate limit exceeded. Resets at: #{reset_time}",
      rate_limit_info: rate_limit_info
    }
  end
end
