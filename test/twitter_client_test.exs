defmodule XClientTest do
  use ExUnit.Case

  describe "client/1" do
    test "creates client with provided credentials" do
      client = XClient.client(
        consumer_key: "test_key",
        consumer_secret: "test_secret",
        access_token: "test_token",
        access_token_secret: "test_token_secret"
      )

      assert client.consumer_key == "test_key"
      assert client.consumer_secret == "test_secret"
      assert client.access_token == "test_token"
      assert client.access_token_secret == "test_token_secret"
    end

    test "creates client with config credentials when not provided" do
      Application.put_env(:x_client, :consumer_key, "config_key")
      Application.put_env(:x_client, :consumer_secret, "config_secret")
      Application.put_env(:x_client, :access_token, "config_token")
      Application.put_env(:x_client, :access_token_secret, "config_token_secret")

      client = XClient.client()

      assert client.consumer_key == "config_key"
      assert client.consumer_secret == "config_secret"
      assert client.access_token == "config_token"
      assert client.access_token_secret == "config_token_secret"

      # Cleanup
      Application.delete_env(:x_client, :consumer_key)
      Application.delete_env(:x_client, :consumer_secret)
      Application.delete_env(:x_client, :access_token)
      Application.delete_env(:x_client, :access_token_secret)
    end
  end
end

defmodule XClient.AuthTest do
  use ExUnit.Case
  alias XClient.Auth

  describe "validate_credentials/1" do
    test "returns :ok when all credentials are present" do
      credentials = %{
        consumer_key: "key",
        consumer_secret: "secret",
        access_token: "token",
        access_token_secret: "token_secret"
      }

      assert Auth.validate_credentials(credentials) == :ok
    end

    test "returns error when credentials are missing" do
      credentials = %{
        consumer_key: "key",
        consumer_secret: nil,
        access_token: "token",
        access_token_secret: ""
      }

      assert {:error, {:missing_credentials, missing}} = Auth.validate_credentials(credentials)
      assert :consumer_secret in missing
      assert :access_token_secret in missing
    end
  end

  describe "generate_nonce/0" do
    test "generates a 32 character nonce" do
      nonce = Auth.generate_nonce()
      assert String.length(nonce) == 32
      assert nonce =~ ~r/^[a-zA-Z0-9]+$/
    end

    test "generates unique nonces" do
      nonce1 = Auth.generate_nonce()
      nonce2 = Auth.generate_nonce()
      assert nonce1 != nonce2
    end
  end
end

defmodule XClient.ConfigTest do
  use ExUnit.Case
  alias XClient.Config

  describe "configuration" do
    test "returns default base_url" do
      assert Config.base_url() == "https://api.x.com/1.1"
    end

    test "returns default upload_url" do
      assert Config.upload_url() == "https://upload.x.com/1.1"
    end

    test "returns default max_retries" do
      assert Config.max_retries() == 3
    end

    test "returns default auto_retry?" do
      assert Config.auto_retry?() == true
    end

    test "returns custom configuration" do
      Application.put_env(:x_client, :max_retries, 5)
      assert Config.max_retries() == 5
      Application.delete_env(:x_client, :max_retries)
    end
  end
end

defmodule XClient.ErrorTest do
  use ExUnit.Case
  alias XClient.Error

  describe "message/1" do
    test "formats error with status and message" do
      error = %Error{status: 404, message: "Not found"}
      assert Error.message(error) =~ "404"
      assert Error.message(error) =~ "Not found"
    end

    test "formats error with code" do
      error = %Error{status: 400, code: 88, message: "Rate limit exceeded"}
      message = Error.message(error)
      assert message =~ "400"
      assert message =~ "88"
      assert message =~ "Rate limit exceeded"
    end
  end

  describe "rate_limited/1" do
    test "creates rate limit error" do
      info = %{reset: 1234567890}
      error = Error.rate_limited(info)

      assert error.status == 429
      assert error.message =~ "Rate limit exceeded"
      assert error.rate_limit_info == info
    end
  end
end

defmodule XClient.RateLimiterTest do
  use ExUnit.Case
  alias XClient.RateLimiter

  setup do
    # Reset rate limiter state before each test
    RateLimiter.reset_all()
    :ok
  end

  describe "check_limit/1" do
    test "allows request when no limit info exists" do
      assert RateLimiter.check_limit("test_endpoint") == :ok
    end

    test "allows request when remaining > 0" do
      RateLimiter.update_limit("test_endpoint", %{
        limit: 100,
        remaining: 50,
        reset: :os.system_time(:second) + 900
      })

      assert RateLimiter.check_limit("test_endpoint") == :ok
    end

    test "blocks request when remaining = 0 and not reset" do
      RateLimiter.update_limit("test_endpoint", %{
        limit: 100,
        remaining: 0,
        reset: :os.system_time(:second) + 900
      })

      assert RateLimiter.check_limit("test_endpoint") == {:error, :rate_limited}
    end

    test "allows request when remaining = 0 but window has reset" do
      RateLimiter.update_limit("test_endpoint", %{
        limit: 100,
        remaining: 0,
        reset: :os.system_time(:second) - 1
      })

      assert RateLimiter.check_limit("test_endpoint") == :ok
    end
  end

  describe "update_limit/2" do
    test "updates rate limit information" do
      info = %{limit: 100, remaining: 99, reset: 1234567890}
      RateLimiter.update_limit("test_endpoint", info)

      stored_info = RateLimiter.get_limit_info("test_endpoint")
      assert stored_info == info
    end
  end

  describe "get_limit_info/1" do
    test "returns nil when no info exists" do
      assert RateLimiter.get_limit_info("nonexistent") == nil
    end

    test "returns stored info" do
      info = %{limit: 100, remaining: 99, reset: 1234567890}
      RateLimiter.update_limit("test_endpoint", info)

      assert RateLimiter.get_limit_info("test_endpoint") == info
    end
  end
end
