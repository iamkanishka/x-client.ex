defmodule XClient.Auth do
  @moduledoc """
  OAuth 1.0a authentication for X API.
  """

  @doc """
  Generates OAuth 1.0a authorization header for a request.

  ## Parameters

    - `method` - HTTP method (e.g., "GET", "POST")
    - `url` - Full URL of the request
    - `params` - Request parameters
    - `credentials` - Map with :consumer_key, :consumer_secret, :access_token, :access_token_secret

  ## Returns

  Authorization header string
  """
  def authorization_header(method, url, params, credentials) do
    credentials_tuple = {
      credentials.consumer_key,
      credentials.consumer_secret,
      credentials.access_token,
      credentials.access_token_secret
    }

    params_list = Enum.map(params, fn {k, v} -> {to_string(k), to_string(v)} end)

    OAuther.sign(method, url, params_list, credentials_tuple)
    |> OAuther.header()
  end

  @doc """
  Generates OAuth parameters for a request.

  Used internally for signing requests.
  """
  def oauth_params(credentials) do
    timestamp = :os.system_time(:second) |> to_string()
    nonce = generate_nonce()

    %{
      "oauth_consumer_key" => credentials.consumer_key,
      "oauth_token" => credentials.access_token,
      "oauth_signature_method" => "HMAC-SHA1",
      "oauth_timestamp" => timestamp,
      "oauth_nonce" => nonce,
      "oauth_version" => "1.0"
    }
  end

  @doc """
  Generates a random nonce for OAuth requests.
  """
  def generate_nonce do
    generate_nonce_until(32)
  end

  defp generate_nonce_until(min_length) do
    # Each call produces 44 base64 chars; after stripping +/= we get ~32.
    # Loop until we have at least min_length alphanumeric characters.
    candidate =
      :crypto.strong_rand_bytes(48)
      |> Base.encode64()
      |> String.replace(~r/[^a-zA-Z0-9]/, "")

    if String.length(candidate) >= min_length do
      String.slice(candidate, 0, min_length)
    else
      generate_nonce_until(min_length)
    end
  end

  @doc """
  Validates that all required credentials are present.

  ## Returns

    - `:ok` if all credentials are present
    - `{:error, :missing_credentials}` if any are missing
  """
  def validate_credentials(credentials) do
    required = [:consumer_key, :consumer_secret, :access_token, :access_token_secret]

    missing =
      Enum.filter(required, fn key ->
        is_nil(Map.get(credentials, key)) || Map.get(credentials, key) == ""
      end)

    case missing do
      [] -> :ok
      keys -> {:error, {:missing_credentials, keys}}
    end
  end
end
