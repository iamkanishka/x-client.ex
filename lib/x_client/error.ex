defmodule XClient.Error do
  @moduledoc """
  Structured error type for all X API failures.

  Implements `Exception` so it can be raised directly, but in normal usage
  it's returned as `{:error, %XClient.Error{}}`.

  ## Fields

    - `:status` – HTTP status code (`nil` for network/internal errors)
    - `:code` – X API error code (from the `errors[].code` field in response bodies)
    - `:message` – Human-readable error message
    - `:errors` – Raw list of error objects from the X API response
    - `:rate_limit_info` – Rate limit headers, present on 429 responses

  ## X API Error Codes (common)

    - `32`  – Could not authenticate you
    - `64`  – Account suspended
    - `88`  – Rate limit exceeded
    - `89`  – Invalid or expired token
    - `130` – Over capacity
    - `131` – Internal error
    - `135` – Timestamp out of bounds
    - `161` – Follow limit reached
    - `179` – Not authorised to see this status
    - `185` – Status update limit reached
    - `187` – Duplicate status
    - `226` – Automated request detected
    - `261` – Application write access suspended
    - `326` – Account locked (suspicious activity)
  """

  @type rate_limit_info :: %{
          optional(:limit) => non_neg_integer(),
          optional(:remaining) => non_neg_integer(),
          optional(:reset) => non_neg_integer()
        }

  @type t :: %__MODULE__{
          status: non_neg_integer() | nil,
          code: non_neg_integer() | nil,
          message: String.t(),
          errors: list(map()) | nil,
          rate_limit_info: rate_limit_info() | nil
        }

  defexception [:status, :code, :message, :errors, :rate_limit_info]

  @impl Exception
  def message(%__MODULE__{status: status, code: code, message: msg}) do
    parts =
      []
      |> maybe_prepend("HTTP #{status}", status)
      |> maybe_prepend("Code #{code}", code)
      |> Enum.reverse()
      |> Kernel.++([msg])

    Enum.join(parts, " | ")
  end

  @doc """
  Constructs a rate-limit error from rate limit header info.
  """
  @spec rate_limited(rate_limit_info()) :: t()
  def rate_limited(info) do
    reset_msg =
      case info[:reset] do
        nil ->
          "unknown time"

        ts ->
          ts
          |> DateTime.from_unix!()
          |> DateTime.to_string()
      end

    %__MODULE__{
      status: 429,
      code: 88,
      message: "Rate limit exceeded. Resets at #{reset_msg}.",
      rate_limit_info: info
    }
  end

  @doc """
  Constructs an error from a decoded X API response body.

  Handles both `{\"errors\": [...]}` and `{\"error\": \"...\"}` shapes.
  """
  @spec from_body(map() | String.t(), non_neg_integer()) :: t()
  def from_body(body, status) when is_map(body) do
    {message, code, errors} = extract_errors(body)
    %__MODULE__{status: status, code: code, message: message, errors: errors}
  end

  def from_body(body, status) when is_binary(body) do
    case Jason.decode(body) do
      {:ok, decoded} -> from_body(decoded, status)
      {:error, _} -> %__MODULE__{status: status, message: body}
    end
  end

  def from_body(body, status), do: %__MODULE__{status: status, message: inspect(body)}

  @doc "Wraps a network-level error (e.g., timeout, DNS failure)."
  @spec network_error(term()) :: t()
  def network_error(reason) do
    %__MODULE__{message: "Network error: #{inspect(reason)}"}
  end

  # ── Private helpers ──────────────────────────────────────────────────────────

  defp extract_errors(%{"errors" => [%{"message" => _msg, "code" => code} | _] = errors}) do
    joined = Enum.map_join(errors, "; ", & &1["message"])
    {joined, code, errors}
  end

  defp extract_errors(%{"errors" => [%{"message" => _msg} | _] = errors}) do
    joined = Enum.map_join(errors, "; ", & &1["message"])
    {joined, nil, errors}
  end

  defp extract_errors(%{"error" => error}) when is_binary(error), do: {error, nil, nil}

  defp extract_errors(body), do: {inspect(body), nil, nil}

  defp maybe_prepend(list, _str, nil), do: list
  defp maybe_prepend(list, str, _val), do: [str | list]
end
