defmodule XClient.HTTPTest do
  @moduledoc """
  Integration tests for XClient.HTTP using Bypass to intercept HTTP calls.

  These tests verify the full request pipeline: credential validation,
  OAuth header generation, request dispatch, rate-limit header ingestion,
  response parsing, and retry behaviour.
  """

  use ExUnit.Case, async: false

  import XClient.Test.Support

  alias XClient.{Error, RateLimiter}

  setup :setup_bypass

  setup do
    put_test_credentials()
    RateLimiter.reset_all()
    on_exit(&delete_test_credentials/0)
    :ok
  end

  # ── Successful responses ─────────────────────────────────────────────────────

  describe "GET request — success" do
    test "returns {:ok, decoded_body} on 200", %{bypass: bypass} do
      body = Jason.encode!(%{"id_string" => "123", "text" => "Hello"})

      Bypass.expect_once(bypass, "GET", "/1.1/statuses/show.json", fn conn ->
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.send_resp(200, body)
      end)

      assert {:ok, %{"id_string" => "123", "text" => "Hello"}} =
               XClient.HTTP.get("statuses/show.json", id: "123")
    end

    test "includes Authorization header in request", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/1.1/account/verify_credentials.json", fn conn ->
        auth = Plug.Conn.get_req_header(conn, "authorization")
        assert auth != []
        assert hd(auth) =~ ~r/^OAuth /

        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.send_resp(200, "{}")
      end)

      XClient.HTTP.get("account/verify_credentials.json")
    end

    test "parses rate-limit headers into RateLimiter", %{bypass: bypass} do
      reset_ts = :os.system_time(:second) + 900

      Bypass.expect_once(bypass, "GET", "/1.1/statuses/user_timeline.json", fn conn ->
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.put_resp_header("x-rate-limit-limit", "900")
        |> Plug.Conn.put_resp_header("x-rate-limit-remaining", "847")
        |> Plug.Conn.put_resp_header("x-rate-limit-reset", to_string(reset_ts))
        |> Plug.Conn.send_resp(200, "[]")
      end)

      {:ok, _} = XClient.HTTP.get("statuses/user_timeline.json")

      # Give the async cast time to land
      Process.sleep(20)
      info = RateLimiter.get_limit_info("statuses/user_timeline.json")
      assert info[:remaining] == 847
      assert info[:limit] == 900
    end

    test "accepts list response body", %{bypass: bypass} do
      body = Jason.encode!([%{"id" => 1}, %{"id" => 2}])

      Bypass.expect_once(bypass, "GET", "/1.1/favorites/list.json", fn conn ->
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.send_resp(200, body)
      end)

      assert {:ok, [%{"id" => 1}, %{"id" => 2}]} = XClient.HTTP.get("favorites/list.json")
    end
  end

  describe "POST request — success" do
    test "sends form-encoded body on POST", %{bypass: bypass} do
      tweet = Jason.encode!(tweet_fixture())

      Bypass.expect_once(bypass, "POST", "/1.1/statuses/update.json", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        assert body =~ "status="

        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.send_resp(200, tweet)
      end)

      assert {:ok, %{"id_string" => _}} =
               XClient.HTTP.post("statuses/update.json", status: "Hello!")
    end

    test "post_json sends application/json content-type", %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/1.1/direct_messages/events/new.json", fn conn ->
        ct = Plug.Conn.get_req_header(conn, "content-type")
        assert hd(ct) =~ "application/json"

        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.send_resp(200, ~s({"event":{}}))
      end)

      json = Jason.encode!(%{"event" => %{"type" => "message_create"}})
      assert {:ok, _} = XClient.HTTP.post_json("direct_messages/events/new.json", json)
    end
  end

  # ── Error responses ──────────────────────────────────────────────────────────

  describe "error responses" do
    test "returns {:error, %Error{}} on 401", %{bypass: bypass} do
      body =
        Jason.encode!(%{"errors" => [%{"message" => "Could not authenticate you.", "code" => 32}]})

      Bypass.expect_once(bypass, "GET", "/1.1/account/verify_credentials.json", fn conn ->
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.send_resp(401, body)
      end)

      assert {:error, %Error{status: 401, code: 32}} =
               XClient.HTTP.get("account/verify_credentials.json")
    end

    test "returns {:error, %Error{status: 404}} on not found", %{bypass: bypass} do
      body =
        Jason.encode!(%{
          "errors" => [%{"message" => "Sorry, that page does not exist", "code" => 34}]
        })

      Bypass.expect_once(bypass, "GET", "/1.1/statuses/show.json", fn conn ->
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.send_resp(404, body)
      end)

      assert {:error, %Error{status: 404, code: 34}} =
               XClient.HTTP.get("statuses/show.json", id: "999")
    end

    test "returns {:error, %Error{status: 403}} on forbidden", %{bypass: bypass} do
      body = Jason.encode!(%{"errors" => [%{"message" => "Duplicate status", "code" => 187}]})

      Bypass.expect_once(bypass, "POST", "/1.1/statuses/update.json", fn conn ->
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.send_resp(403, body)
      end)

      assert {:error, %Error{status: 403, code: 187, message: msg}} =
               XClient.HTTP.post("statuses/update.json", status: "Dup")

      assert msg =~ "Duplicate"
    end
  end

  # ── Rate limiting ────────────────────────────────────────────────────────────

  describe "429 rate limit handling" do
    test "returns {:error, %Error{status: 429}} when auto_retry disabled", %{bypass: bypass} do
      Application.put_env(:x_client, :auto_retry, false)

      reset_ts = :os.system_time(:second) + 900

      Bypass.expect_once(bypass, "GET", "/1.1/statuses/user_timeline.json", fn conn ->
        conn
        |> Plug.Conn.put_resp_header("x-rate-limit-remaining", "0")
        |> Plug.Conn.put_resp_header("x-rate-limit-reset", to_string(reset_ts))
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.send_resp(429, ~s({"errors":[{"message":"Rate limit exceeded","code":88}]}))
      end)

      assert {:error, %Error{status: 429}} = XClient.HTTP.get("statuses/user_timeline.json")
    after
      Application.delete_env(:x_client, :auto_retry)
    end

    test "pre-request check blocks when endpoint is exhausted", %{bypass: _bypass} do
      # Load the rate limiter with a zero-remaining entry for the future
      RateLimiter.update_limit("statuses/user_timeline.json", %{
        remaining: 0,
        reset: :os.system_time(:second) + 900
      })

      Process.sleep(20)

      assert {:error, %Error{status: 429}} = XClient.HTTP.get("statuses/user_timeline.json")
    end
  end

  # ── Credential validation ────────────────────────────────────────────────────

  describe "credential validation" do
    test "returns {:error, %Error{}} when credentials are missing" do
      delete_test_credentials()

      assert {:error, %Error{message: message}} = XClient.HTTP.get("statuses/user_timeline.json")

      assert message =~ "missing_credentials" or message =~ "credentials"
    end

    test "per-request client overrides application config", %{bypass: bypass} do
      # Override with valid test credentials
      client = test_client()

      Bypass.expect_once(bypass, "GET", "/1.1/statuses/user_timeline.json", fn conn ->
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.send_resp(200, "[]")
      end)

      assert {:ok, []} = XClient.HTTP.get("statuses/user_timeline.json", [], client)
    end
  end
end
