defmodule XClient.Config do
  @moduledoc """
  Configuration management for X API credentials.
  """

  @doc """
  Gets the consumer key from configuration.
  """
  def consumer_key do
    get_config(:consumer_key)
  end

  @doc """
  Gets the consumer secret from configuration.
  """
  def consumer_secret do
    get_config(:consumer_secret)
  end

  @doc """
  Gets the access token from configuration.
  """
  def access_token do
    get_config(:access_token)
  end

  @doc """
  Gets the access token secret from configuration.
  """
  def access_token_secret do
    get_config(:access_token_secret)
  end

  @doc """
  Gets the base URL for the X API.
  Default: "https://api.x.com/1.1"
  """
  def base_url do
    Application.get_env(:x_client, :base_url, "https://api.x.com/1.1")
  end

  @doc """
  Gets the upload URL for media uploads.
  Default: "https://upload.x.com/1.1"
  """
  def upload_url do
    Application.get_env(:x_client, :upload_url, "https://upload.x.com/1.1")
  end

  @doc """
  Gets the maximum retries for rate limited requests.
  Default: 3
  """
  def max_retries do
    Application.get_env(:x_client, :max_retries, 3)
  end

  @doc """
  Gets whether to automatically retry rate limited requests.
  Default: true
  """
  def auto_retry? do
    Application.get_env(:x_client, :auto_retry, true)
  end

  # Private helpers

  defp get_config(key) do
    case Application.get_env(:x_client, key) do
      {:system, env_var} -> System.get_env(env_var)
      value -> value
    end
  end
end
