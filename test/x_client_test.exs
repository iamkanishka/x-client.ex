defmodule XClient.AuthTest do
  use ExUnit.Case, async: true
  alias XClient.{Auth, Client}

  @valid_client %Client{
    consumer_key: "ck",
    consumer_secret: "cs",
    access_token: "at",
    access_token_secret: "ats"
  }

  describe "validate_credentials/1" do
    test "returns :ok when all credentials are present" do
      assert Auth.validate_credentials(@valid_client) == :ok
    end

    test "returns error when consumer_secret is nil" do
      client = %Client{@valid_client | consumer_secret: nil}

      assert {:error, {:missing_credentials, [:consumer_secret]}} =
               Auth.validate_credentials(client)
    end

    test "returns error when access_token_secret is empty string" do
      client = %Client{@valid_client | access_token_secret: ""}

      assert {:error, {:missing_credentials, [:access_token_secret]}} =
               Auth.validate_credentials(client)
    end

    test "lists all missing credentials" do
      client = %Client{@valid_client | consumer_key: nil, access_token: ""}
      assert {:error, {:missing_credentials, missing}} = Auth.validate_credentials(client)
      assert :consumer_key in missing
      assert :access_token in missing
    end
  end

  describe "generate_nonce/0" do
    test "returns exactly 32 alphanumeric characters" do
      nonce = Auth.generate_nonce()
      assert String.length(nonce) == 32
      assert nonce =~ ~r/\A[a-zA-Z0-9]+\z/
    end

    test "returns unique nonces on repeated calls" do
      nonces = for _ <- 1..20, do: Auth.generate_nonce()
      assert length(Enum.uniq(nonces)) == 20
    end
  end

  describe "authorization_header/4" do
    test "returns a string starting with 'OAuth '" do
      header = Auth.authorization_header(:get, "https://api.x.com/1.1/test.json", [], @valid_client)
      assert is_binary(header)
      assert String.starts_with?(header, "OAuth ")
    end

    test "works with atom and string method names" do
      h1 = Auth.authorization_header(:get, "https://api.x.com/1.1/test.json", [], @valid_client)
      h2 = Auth.authorization_header("GET", "https://api.x.com/1.1/test.json", [], @valid_client)
      # Both should be valid OAuth headers (values will differ due to nonce/timestamp)
      assert String.starts_with?(h1, "OAuth ")
      assert String.starts_with?(h2, "OAuth ")
    end

    test "includes oauth_consumer_key" do
      header = Auth.authorization_header(:get, "https://api.x.com/1.1/test.json", [], @valid_client)
      assert header =~ "oauth_consumer_key"
    end

    test "includes oauth_signature" do
      header = Auth.authorization_header(:get, "https://api.x.com/1.1/test.json", [], @valid_client)
      assert header =~ "oauth_signature="
    end
  end
end

defmodule XClient.ClientTest do
  use ExUnit.Case, async: true
  alias XClient.Client

  test "enforces required fields at struct creation" do
    assert_raise ArgumentError, fn ->
      struct!(Client, %{})
    end
  end

  test "to_oauther_credentials returns 4-tuple" do
    client = %Client{
      consumer_key: "ck",
      consumer_secret: "cs",
      access_token: "at",
      access_token_secret: "ats"
    }

    assert {"ck", "cs", "at", "ats"} = Client.to_oauther_credentials(client)
  end
end

defmodule XClientTest do
  use ExUnit.Case, async: true

  describe "client/1" do
    test "creates a %Client{} with provided credentials" do
      client =
        XClient.client(
          consumer_key: "ck",
          consumer_secret: "cs",
          access_token: "at",
          access_token_secret: "ats"
        )

      assert %XClient.Client{} = client
      assert client.consumer_key == "ck"
      assert client.consumer_secret == "cs"
      assert client.access_token == "at"
      assert client.access_token_secret == "ats"
    end

    test "falls back to application config for missing keys" do
      Application.put_env(:x_client, :consumer_key, "cfg_ck")
      Application.put_env(:x_client, :consumer_secret, "cfg_cs")
      Application.put_env(:x_client, :access_token, "cfg_at")
      Application.put_env(:x_client, :access_token_secret, "cfg_ats")

      client = XClient.client()

      assert client.consumer_key == "cfg_ck"
      assert client.consumer_secret == "cfg_cs"
    after
      Application.delete_env(:x_client, :consumer_key)
      Application.delete_env(:x_client, :consumer_secret)
      Application.delete_env(:x_client, :access_token)
      Application.delete_env(:x_client, :access_token_secret)
    end
  end
end

defmodule XClient.ConfigTest do
  use ExUnit.Case, async: true
  alias XClient.Config

  test "base_url defaults to api.x.com" do
    assert Config.base_url() == "https://api.x.com/1.1"
  end

  test "upload_url defaults to upload.x.com" do
    assert Config.upload_url() == "https://upload.x.com/1.1"
  end

  test "max_retries defaults to 3" do
    assert Config.max_retries() == 3
  end

  test "auto_retry? defaults to true" do
    assert Config.auto_retry?() == true
  end

  test "retry_base_delay_ms defaults to 1000" do
    assert Config.retry_base_delay_ms() == 1_000
  end

  test "request_timeout_ms defaults to 30_000" do
    assert Config.request_timeout_ms() == 30_000
  end

  test "custom integer values are returned directly" do
    Application.put_env(:x_client, :max_retries, 10)
    assert Config.max_retries() == 10
  after
    Application.delete_env(:x_client, :max_retries)
  end

  test "{:system, env_var} reads from environment" do
    System.put_env("X_TEST_KEY", "env_value")
    Application.put_env(:x_client, :consumer_key, {:system, "X_TEST_KEY"})

    assert Config.consumer_key() == "env_value"
  after
    System.delete_env("X_TEST_KEY")
    Application.delete_env(:x_client, :consumer_key)
  end

  describe "validate!/0" do
    test "returns :ok when all credentials configured" do
      Application.put_env(:x_client, :consumer_key, "ck")
      Application.put_env(:x_client, :consumer_secret, "cs")
      Application.put_env(:x_client, :access_token, "at")
      Application.put_env(:x_client, :access_token_secret, "ats")

      assert Config.validate!() == :ok
    after
      Enum.each(
        [:consumer_key, :consumer_secret, :access_token, :access_token_secret],
        &Application.delete_env(:x_client, &1)
      )
    end

    test "returns error listing missing keys" do
      Enum.each(
        [:consumer_key, :consumer_secret, :access_token, :access_token_secret],
        &Application.delete_env(:x_client, &1)
      )

      assert {:error, {:missing_config, missing}} = Config.validate!()
      assert :consumer_key in missing
      assert :consumer_secret in missing
    end
  end
end

defmodule XClient.ErrorTest do
  use ExUnit.Case, async: true
  alias XClient.Error

  describe "message/1" do
    test "includes HTTP status and message" do
      err = %Error{status: 404, message: "Not found"}
      msg = Error.message(err)
      assert msg =~ "404"
      assert msg =~ "Not found"
    end

    test "includes code when present" do
      err = %Error{status: 400, code: 187, message: "Duplicate status"}
      msg = Error.message(err)
      assert msg =~ "400"
      assert msg =~ "187"
      assert msg =~ "Duplicate status"
    end

    test "works without status or code" do
      err = %Error{message: "Network timeout"}
      assert Error.message(err) == "Network timeout"
    end
  end

  describe "rate_limited/1" do
    test "creates a 429 error" do
      err = Error.rate_limited(%{reset: 1_700_000_000})
      assert err.status == 429
      assert err.code == 88
      assert err.message =~ "Rate limit exceeded"
    end

    test "handles nil reset gracefully" do
      err = Error.rate_limited(%{})
      assert err.status == 429
      assert err.message =~ "Rate limit exceeded"
    end
  end

  describe "from_body/2" do
    test "extracts errors list" do
      body = %{"errors" => [%{"message" => "Sorry, you are not authorized.", "code" => 32}]}
      err = Error.from_body(body, 401)
      assert err.status == 401
      assert err.code == 32
      assert err.message =~ "not authorized"
      assert length(err.errors) == 1
    end

    test "extracts simple error string" do
      err = Error.from_body(%{"error" => "read-only application"}, 403)
      assert err.status == 403
      assert err.message == "read-only application"
    end

    test "parses JSON string body" do
      json = Jason.encode!(%{"errors" => [%{"message" => "Rate limit exceeded", "code" => 88}]})
      err = Error.from_body(json, 429)
      assert err.status == 429
      assert err.code == 88
    end

    test "handles multiple errors" do
      body = %{
        "errors" => [
          %{"message" => "Sorry, that page does not exist", "code" => 34},
          %{"message" => "Cannot find specified user.", "code" => 108}
        ]
      }

      err = Error.from_body(body, 404)
      assert err.message =~ "that page does not exist"
      assert err.message =~ "Cannot find specified user"
    end
  end

  describe "network_error/1" do
    test "wraps connection refused" do
      err = Error.network_error(%{reason: :econnrefused})
      assert err.message =~ "Network error"
      assert is_nil(err.status)
    end
  end
end

defmodule XClient.ParamsTest do
  use ExUnit.Case, async: true
  alias XClient.Params

  describe "build/1" do
    test "converts keyword list to map" do
      assert Params.build(screen_name: "user", count: 50) == %{screen_name: "user", count: 50}
    end

    test "joins lists with commas" do
      assert Params.build(ids: ["a", "b", "c"]) == %{ids: "a,b,c"}
    end

    test "converts true to string 'true'" do
      assert Params.build(include_entities: true) == %{include_entities: "true"}
    end

    test "converts false to string 'false'" do
      assert Params.build(trim_user: false) == %{trim_user: "false"}
    end

    test "drops nil values" do
      assert Params.build(screen_name: "user", count: nil) == %{screen_name: "user"}
    end

    test "accepts a map" do
      assert Params.build(%{q: "elixir", count: 10}) == %{q: "elixir", count: 10}
    end
  end

  describe "build/2" do
    test "merges extra keyword pairs" do
      result = Params.build([count: 50], id: "123")
      assert result == %{count: 50, id: "123"}
    end

    test "extra pairs override opts" do
      result = Params.build([id: "old"], id: "new")
      assert result == %{id: "new"}
    end
  end
end

defmodule XClient.RateLimiterTest do
  use ExUnit.Case

  alias XClient.RateLimiter

  setup do
    RateLimiter.reset_all()
    :ok
  end

  describe "check_limit/1" do
    test "returns :ok when no info stored for endpoint" do
      assert :ok = RateLimiter.check_limit("statuses/user_timeline.json")
    end

    test "returns :ok when remaining > 0" do
      RateLimiter.update_limit("ep1", %{remaining: 5, reset: far_future()})
      assert :ok = RateLimiter.check_limit("ep1")
    end

    test "returns {:error, :rate_limited} when remaining = 0 and window not reset" do
      RateLimiter.update_limit("ep2", %{remaining: 0, reset: far_future()})
      # Give the cast time to process
      :timer.sleep(10)
      assert {:error, :rate_limited} = RateLimiter.check_limit("ep2")
    end

    test "returns :ok when remaining = 0 but window has already reset" do
      RateLimiter.update_limit("ep3", %{remaining: 0, reset: past()})
      :timer.sleep(10)
      assert :ok = RateLimiter.check_limit("ep3")
    end

    test "different endpoints are independent" do
      RateLimiter.update_limit("ep_a", %{remaining: 0, reset: far_future()})
      RateLimiter.update_limit("ep_b", %{remaining: 50, reset: far_future()})
      :timer.sleep(10)
      assert {:error, :rate_limited} = RateLimiter.check_limit("ep_a")
      assert :ok = RateLimiter.check_limit("ep_b")
    end
  end

  describe "update_limit/2 and get_limit_info/1" do
    test "stored info is retrievable via ETS directly" do
      info = %{limit: 900, remaining: 847, reset: far_future()}
      RateLimiter.update_limit("ep", info)
      :timer.sleep(10)
      assert RateLimiter.get_limit_info("ep") == info
    end

    test "returns nil for unknown endpoint" do
      assert RateLimiter.get_limit_info("nonexistent") == nil
    end
  end

  describe "reset_all/0" do
    test "clears all stored limits" do
      RateLimiter.update_limit("x", %{remaining: 0, reset: far_future()})
      :timer.sleep(10)
      RateLimiter.reset_all()
      assert RateLimiter.get_limit_info("x") == nil
    end
  end

  defp far_future, do: :os.system_time(:second) + 900
  defp past, do: :os.system_time(:second) - 1
end

defmodule XClient.HTTPIntegrationTest do
  use ExUnit.Case

  alias XClient.{Client, Error}

  @client %Client{
    consumer_key: "ck",
    consumer_secret: "cs",
    access_token: "at",
    access_token_secret: "ats"
  }

  setup do
    bypass = Bypass.open()
    Application.put_env(:x_client, :base_url, "http://localhost:#{bypass.port}")
    on_exit(fn -> Application.delete_env(:x_client, :base_url) end)
    {:ok, bypass: bypass}
  end

  test "GET returns parsed JSON on 200", %{bypass: bypass} do
    Bypass.expect_once(bypass, "GET", "/statuses/user_timeline.json", fn conn ->
      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.send_resp(200, Jason.encode!([%{"id_str" => "123", "text" => "Hello"}]))
    end)

    assert {:ok, [%{"id_str" => "123"}]} =
             XClient.HTTP.get("statuses/user_timeline.json", [screen_name: "user"], @client)
  end

  test "returns structured Error on 401", %{bypass: bypass} do
    body =
      Jason.encode!(%{"errors" => [%{"message" => "Could not authenticate you.", "code" => 32}]})

    Bypass.expect_once(bypass, "GET", "/account/verify_credentials.json", fn conn ->
      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.send_resp(401, body)
    end)

    assert {:error, %Error{status: 401, code: 32}} =
             XClient.HTTP.get("account/verify_credentials.json", [], @client)
  end

  test "returns rate_limited Error on 429", %{bypass: bypass} do
    Application.put_env(:x_client, :auto_retry, false)

    Bypass.expect_once(bypass, "GET", "/search/tweets.json", fn conn ->
      conn
      |> Plug.Conn.put_resp_header("x-rate-limit-limit", "450")
      |> Plug.Conn.put_resp_header("x-rate-limit-remaining", "0")
      |> Plug.Conn.put_resp_header("x-rate-limit-reset", "9999999999")
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.send_resp(
        429,
        Jason.encode!(%{"errors" => [%{"code" => 88, "message" => "Rate limit exceeded"}]})
      )
    end)

    assert {:error, %Error{status: 429}} =
             XClient.HTTP.get("search/tweets.json", [q: "elixir"], @client)
  after
    Application.delete_env(:x_client, :auto_retry)
  end

  test "returns validation error when credentials missing" do
    bad_client = %Client{
      consumer_key: nil,
      consumer_secret: "cs",
      access_token: "at",
      access_token_secret: "ats"
    }

    assert {:error, {:missing_credentials, _}} =
             XClient.HTTP.get("statuses/user_timeline.json", [], bad_client)
  end

  test "ingests rate limit headers from successful response", %{bypass: bypass} do
    XClient.RateLimiter.reset_all()

    Bypass.expect_once(bypass, "GET", "/statuses/show.json", fn conn ->
      conn
      |> Plug.Conn.put_resp_header("x-rate-limit-limit", "900")
      |> Plug.Conn.put_resp_header("x-rate-limit-remaining", "899")
      |> Plug.Conn.put_resp_header("x-rate-limit-reset", "9999999999")
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.send_resp(200, Jason.encode!(%{"id_str" => "123"}))
    end)

    assert {:ok, _} = XClient.HTTP.get("statuses/show.json", [id: "123"], @client)
    :timer.sleep(20)

    info = XClient.RateLimiter.get_limit_info("statuses/show.json")
    assert info[:remaining] == 899
    assert info[:limit] == 900
  end
end
