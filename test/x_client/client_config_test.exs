defmodule XClient.ClientTest do
  use ExUnit.Case, async: true

  alias XClient.{Client, Config}
  import XClient.Test.Support

  describe "XClient.client/1" do
    setup do
      put_test_credentials()
      on_exit(&delete_test_credentials/0)
      :ok
    end

    test "returns a %Client{} struct" do
      assert %Client{} = XClient.client()
    end

    test "uses provided credentials when all given" do
      client =
        XClient.client(
          consumer_key: "CK",
          consumer_secret: "CS",
          access_token: "AT",
          access_token_secret: "ATS"
        )

      assert client.consumer_key == "CK"
      assert client.consumer_secret == "CS"
      assert client.access_token == "AT"
      assert client.access_token_secret == "ATS"
    end

    test "falls back to application config for missing keys" do
      client = XClient.client()

      assert client.consumer_key == "env_consumer_key"
      assert client.consumer_secret == "env_consumer_secret"
      assert client.access_token == "env_access_token"
      assert client.access_token_secret == "env_access_token_secret"
    end

    test "partial override: provided keys take precedence" do
      client = XClient.client(consumer_key: "override_key")

      assert client.consumer_key == "override_key"
      assert client.consumer_secret == "env_consumer_secret"
    end

    test "client is a typed struct, not a plain map" do
      client = XClient.client()
      refute is_map(client) and Map.has_key?(client, :__struct__) == false
      assert client.__struct__ == XClient.Client
    end
  end

  describe "XClient.Client.to_oauther_credentials/1" do
    test "returns a 4-tuple of credential strings" do
      client = test_client()
      creds = Client.to_oauther_credentials(client)

      assert {ck, cs, at, ats} = creds
      assert ck == "test_consumer_key"
      assert cs == "test_consumer_secret"
      assert at == "test_access_token"
      assert ats == "test_access_token_secret"
    end
  end
end

defmodule XClient.ConfigTest do
  use ExUnit.Case, async: false

  alias XClient.Config

  describe "defaults" do
    test "base_url" do
      assert Config.base_url() == "https://api.x.com/1.1"
    end

    test "upload_url" do
      assert Config.upload_url() == "https://upload.x.com/1.1"
    end

    test "max_retries" do
      assert Config.max_retries() == 3
    end

    test "auto_retry? is true" do
      assert Config.auto_retry?() == true
    end

    test "retry_base_delay_ms" do
      assert Config.retry_base_delay_ms() == 1_000
    end

    test "request_timeout_ms" do
      assert Config.request_timeout_ms() == 30_000
    end
  end

  describe "custom config via Application.put_env" do
    test "respects custom max_retries" do
      Application.put_env(:x_client, :max_retries, 5)
      assert Config.max_retries() == 5
    after
      Application.delete_env(:x_client, :max_retries)
    end

    test "respects auto_retry: false" do
      Application.put_env(:x_client, :auto_retry, false)
      assert Config.auto_retry?() == false
    after
      Application.delete_env(:x_client, :auto_retry)
    end

    test "respects custom base_url" do
      Application.put_env(:x_client, :base_url, "http://localhost:4000")
      assert Config.base_url() == "http://localhost:4000"
    after
      Application.delete_env(:x_client, :base_url)
    end
  end

  describe "{:system, env_var} indirection" do
    test "reads value from environment variable" do
      System.put_env("TEST_X_KEY", "from_env")
      Application.put_env(:x_client, :consumer_key, {:system, "TEST_X_KEY"})
      assert Config.consumer_key() == "from_env"
    after
      System.delete_env("TEST_X_KEY")
      Application.delete_env(:x_client, :consumer_key)
    end

    test "returns nil when env var is not set" do
      Application.put_env(:x_client, :consumer_key, {:system, "UNSET_VAR_XYZ"})
      assert is_nil(Config.consumer_key())
    after
      Application.delete_env(:x_client, :consumer_key)
    end
  end

  describe "validate!/0" do
    test "returns :ok when all credentials are set" do
      Application.put_env(:x_client, :consumer_key, "ck")
      Application.put_env(:x_client, :consumer_secret, "cs")
      Application.put_env(:x_client, :access_token, "at")
      Application.put_env(:x_client, :access_token_secret, "ats")

      assert Config.validate!() == :ok
    after
      for k <- [:consumer_key, :consumer_secret, :access_token, :access_token_secret],
          do: Application.delete_env(:x_client, k)
    end

    test "returns error listing missing keys" do
      Application.put_env(:x_client, :consumer_key, "ck")
      Application.delete_env(:x_client, :consumer_secret)
      Application.delete_env(:x_client, :access_token)
      Application.delete_env(:x_client, :access_token_secret)

      assert {:error, {:missing_config, missing}} = Config.validate!()
      assert :consumer_secret in missing
      assert :access_token in missing
      assert :access_token_secret in missing
    after
      for k <- [:consumer_key, :consumer_secret, :access_token, :access_token_secret],
          do: Application.delete_env(:x_client, k)
    end
  end
end
