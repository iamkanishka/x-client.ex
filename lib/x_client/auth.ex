defmodule XClient.Auth do
  @moduledoc """
  OAuth 1.0a request signing for X API.

  Uses the `oauther` library for HMAC-SHA1 signature generation.
  All functions are pure — no side effects, no GenServer dependencies.
  """

  alias XClient.Client

  @nonce_length 32

  @doc """
  Returns an `Authorization` header value for the given request.

  ## Parameters

    - `method` – HTTP method atom or string (`:get`, `"POST"`, …)
    - `url` – Full request URL (without query string)
    - `params` – Keyword list or map of request parameters included in the OAuth signature base
    - `client` – `%XClient.Client{}` with OAuth credentials

  ## Returns

    Authorization header string starting with `"OAuth "`.
  """
  @spec authorization_header(atom() | String.t(), String.t(), keyword() | map(), Client.t()) ::
          String.t()
  def authorization_header(method, url, params, %Client{} = client) do
    method_str = method |> to_string() |> String.upcase()
    params_list = normalise_params(params)

    # OAuther.sign/4 requires an %OAuther.Credentials{} struct — not a raw tuple.
    # OAuther.credentials/1 builds it from a keyword list.
    creds =
      OAuther.credentials(
        consumer_key: client.consumer_key,
        consumer_secret: client.consumer_secret,
        token: client.access_token,
        token_secret: client.access_token_secret
      )

    # OAuther.header/1 returns {{"Authorization", value}, rest_params}.
    # We pattern-match to extract only the header value string.
    {{"Authorization", auth_value}, _rest} =
      method_str
      |> OAuther.sign(url, params_list, creds)
      |> OAuther.header()

    auth_value
  end

  @doc """
  Validates that all OAuth credentials on a `%Client{}` struct are non-empty strings.

  ## Returns

    - `:ok` on success
    - `{:error, {:missing_credentials, [key]}}` listing missing/empty fields
  """
  @spec validate_credentials(Client.t()) :: :ok | {:error, {:missing_credentials, [atom()]}}
  def validate_credentials(%Client{} = client) do
    required = [:consumer_key, :consumer_secret, :access_token, :access_token_secret]

    missing =
      Enum.filter(required, fn key ->
        val = Map.get(client, key)
        is_nil(val) || val == ""
      end)

    case missing do
      [] -> :ok
      keys -> {:error, {:missing_credentials, keys}}
    end
  end

  @doc """
  Generates a cryptographically random, URL-safe OAuth nonce of `#{@nonce_length}` characters.
  """
  @spec generate_nonce() :: String.t()
  def generate_nonce do
    # 48 bytes → 64 base64 chars → strip non-alnum → ≥ 32 chars almost certainly
    generate_nonce_loop(@nonce_length)
  end

  # ── Private ──────────────────────────────────────────────────────────────────

  defp generate_nonce_loop(min_length) do
    candidate =
      :crypto.strong_rand_bytes(48)
      |> Base.encode64()
      |> String.replace(~r/[^a-zA-Z0-9]/, "")

    if String.length(candidate) >= min_length do
      String.slice(candidate, 0, min_length)
    else
      # Extremely rare: retry if base64 stripping left fewer chars than needed
      generate_nonce_loop(min_length)
    end
  end

  @spec normalise_params(keyword() | map()) :: [{String.t(), String.t()}]
  defp normalise_params(params) when is_map(params) do
    Enum.map(params, fn {k, v} -> {to_string(k), to_string(v)} end)
  end

  defp normalise_params(params) when is_list(params) do
    Enum.map(params, fn {k, v} -> {to_string(k), to_string(v)} end)
  end
end
