defmodule XClient.Test.Support do
  @moduledoc """
  Shared helpers and fixtures for XClient tests.
  """
  import ExUnit.Callbacks
  alias XClient.Client

  @doc "Returns a valid %Client{} struct with stub credentials."
  def test_client do
    %Client{
      consumer_key: "test_consumer_key",
      consumer_secret: "test_consumer_secret",
      access_token: "test_access_token",
      access_token_secret: "test_access_token_secret"
    }
  end

  @doc "Configures Application env with test credentials (call in setup, restore in teardown)."
  def put_test_credentials do
    Application.put_env(:x_client, :consumer_key, "env_consumer_key")
    Application.put_env(:x_client, :consumer_secret, "env_consumer_secret")
    Application.put_env(:x_client, :access_token, "env_access_token")
    Application.put_env(:x_client, :access_token_secret, "env_access_token_secret")
  end

  @doc "Cleans up credentials set by put_test_credentials/0."
  def delete_test_credentials do
    for key <- [:consumer_key, :consumer_secret, :access_token, :access_token_secret] do
      Application.delete_env(:x_client, key)
    end
  end

  @doc "Builds a minimal tweet map fixture."
  def tweet_fixture(overrides \\ %{}) do
    Map.merge(
      %{
        "id" => 123_456_789,
        "id_string" => "123456789",
        "text" => "Hello from Elixir!",
        "user" => user_fixture()
      },
      overrides
    )
  end

  @doc "Builds a minimal user map fixture."
  def user_fixture(overrides \\ %{}) do
    Map.merge(
      %{
        "id" => 987_654_321,
        "id_string" => "987654321",
        "screen_name" => "elixirlang",
        "name" => "Elixir Lang"
      },
      overrides
    )
  end

  @doc "Builds a minimal media map fixture."
  def media_fixture(overrides \\ %{}) do
    Map.merge(
      %{
        "media_id" => 111_222_333,
        "media_id_string" => "111222333",
        "size" => 12_345
      },
      overrides
    )
  end

  @doc """
  Returns JSON-encoded rate-limit headers suitable for Bypass responses.
  """
  def rate_limit_headers(remaining \\ 100, limit \\ 900) do
    reset = :os.system_time(:second) + 900

    [
      {"x-rate-limit-limit", to_string(limit)},
      {"x-rate-limit-remaining", to_string(remaining)},
      {"x-rate-limit-reset", to_string(reset)}
    ]
  end

  @doc "Sets up a Bypass instance and configures XClient to point at it."
  def setup_bypass(context) do
    bypass = Bypass.open()

    original_base = Application.get_env(:x_client, :base_url)
    original_upload = Application.get_env(:x_client, :upload_url)

    base_url = "http://localhost:#{bypass.port}"
    Application.put_env(:x_client, :base_url, base_url)
    Application.put_env(:x_client, :upload_url, base_url)

    on_exit(fn ->
      if original_base, do: Application.put_env(:x_client, :base_url, original_base)
      if original_upload, do: Application.put_env(:x_client, :upload_url, original_upload)
    end)

    Map.put(context, :bypass, bypass)
  end
end
