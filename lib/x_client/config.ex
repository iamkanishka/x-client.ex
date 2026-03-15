defmodule XClient.Config do
  @moduledoc """
  Configuration management for X API credentials and client options.

  ## Application Config

      config :x_client,
        consumer_key: "YOUR_CONSUMER_KEY",
        consumer_secret: "YOUR_CONSUMER_SECRET",
        access_token: "YOUR_ACCESS_TOKEN",
        access_token_secret: "YOUR_ACCESS_TOKEN_SECRET",
        base_url: "https://api.x.com/1.1",
        upload_url: "https://upload.x.com/1.1",
        auto_retry: true,
        max_retries: 3,
        retry_base_delay_ms: 1_000,
        request_timeout_ms: 30_000

  ## Environment Variable Indirection

      config :x_client, consumer_key: {:system, "X_CONSUMER_KEY"}
  """

  @default_base_url "https://api.x.com/1.1"
  @default_upload_url "https://upload.x.com/1.1"
  @default_max_retries 3
  @default_retry_base_delay_ms 1_000
  @default_request_timeout_ms 30_000

  @doc "OAuth consumer key."
  @spec consumer_key() :: String.t() | nil
  def consumer_key, do: fetch(:consumer_key)

  @doc "OAuth consumer secret."
  @spec consumer_secret() :: String.t() | nil
  def consumer_secret, do: fetch(:consumer_secret)

  @doc "OAuth access token."
  @spec access_token() :: String.t() | nil
  def access_token, do: fetch(:access_token)

  @doc "OAuth access token secret."
  @spec access_token_secret() :: String.t() | nil
  def access_token_secret, do: fetch(:access_token_secret)

  @doc "Base URL for the X API. Defaults to `\"https://api.x.com/1.1\"`."
  @spec base_url() :: String.t()
  def base_url, do: Application.get_env(:x_client, :base_url, @default_base_url)

  @doc "Upload URL for media. Defaults to `\"https://upload.x.com/1.1\"`."
  @spec upload_url() :: String.t()
  def upload_url, do: Application.get_env(:x_client, :upload_url, @default_upload_url)

  @doc "Maximum number of automatic retries on rate-limit or transient errors. Defaults to `3`."
  @spec max_retries() :: non_neg_integer()
  def max_retries, do: Application.get_env(:x_client, :max_retries, @default_max_retries)

  @doc "Whether automatic retry is enabled. Defaults to `true`."
  @spec auto_retry?() :: boolean()
  def auto_retry?, do: Application.get_env(:x_client, :auto_retry, true)

  @doc "Base delay (ms) for exponential backoff. Doubles on each retry. Defaults to `1_000`."
  @spec retry_base_delay_ms() :: pos_integer()
  def retry_base_delay_ms,
    do: Application.get_env(:x_client, :retry_base_delay_ms, @default_retry_base_delay_ms)

  @doc "HTTP request timeout in milliseconds. Defaults to `30_000`."
  @spec request_timeout_ms() :: pos_integer()
  def request_timeout_ms,
    do: Application.get_env(:x_client, :request_timeout_ms, @default_request_timeout_ms)

  @doc """
  Validates that all required credentials are configured.

  Returns `:ok` or `{:error, {:missing_config, [key]}}`.
  """
  @spec validate!() :: :ok | {:error, {:missing_config, [atom()]}}
  def validate! do
    required = [:consumer_key, :consumer_secret, :access_token, :access_token_secret]

    missing =
      Enum.filter(required, fn key ->
        value = fetch(key)
        is_nil(value) || value == ""
      end)

    case missing do
      [] -> :ok
      keys -> {:error, {:missing_config, keys}}
    end
  end

  # Private

  @spec fetch(atom()) :: String.t() | nil
  defp fetch(key) do
    case Application.get_env(:x_client, key) do
      {:system, env_var} when is_binary(env_var) ->
        System.get_env(env_var)

      value ->
        value
    end
  end
end
