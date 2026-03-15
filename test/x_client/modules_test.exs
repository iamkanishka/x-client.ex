defmodule XClient.DirectMessagesTest do
  use ExUnit.Case, async: false

  import XClient.Test.Support

  setup :setup_bypass

  setup do
    put_test_credentials()
    on_exit(&delete_test_credentials/0)
    :ok
  end

  describe "send/4" do
    test "POSTs JSON event to direct_messages/events/new.json", %{bypass: bypass} do
      Bypass.expect_once(
        bypass,
        "POST",
        "/1.1/direct_messages/events/new.json",
        fn conn ->
          {:ok, raw_body, conn} = Plug.Conn.read_body(conn)
          body = Jason.decode!(raw_body)

          event = body["event"]
          assert event["type"] == "message_create"
          assert event["message_create"]["target"]["recipient_id"] == "987654"
          assert event["message_create"]["message_data"]["text"] == "Hello!"

          conn
          |> Plug.Conn.put_resp_header("content-type", "application/json")
          |> Plug.Conn.send_resp(200, Jason.encode!(%{"event" => %{"id" => "111"}}))
        end
      )

      assert {:ok, %{"event" => %{"id" => "111"}}} = XClient.DirectMessages.send("987654", "Hello!")
    end

    test "includes media attachment when media_id provided", %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/1.1/direct_messages/events/new.json", fn conn ->
        {:ok, raw_body, conn} = Plug.Conn.read_body(conn)
        body = Jason.decode!(raw_body)
        msg_data = body["event"]["message_create"]["message_data"]

        assert msg_data["attachment"]["type"] == "media"
        assert msg_data["attachment"]["media"]["id"] == "999"

        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.send_resp(200, ~s({"event":{}}))
      end)

      assert {:ok, _} = XClient.DirectMessages.send("987654", "See this!", media_id: "999")
    end

    test "includes quick_reply options when provided", %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/1.1/direct_messages/events/new.json", fn conn ->
        {:ok, raw_body, conn} = Plug.Conn.read_body(conn)
        body = Jason.decode!(raw_body)
        msg_data = body["event"]["message_create"]["message_data"]

        assert msg_data["quick_reply"]["type"] == "options"
        labels = Enum.map(msg_data["quick_reply"]["options"], & &1["label"])
        assert labels == ["Yes", "No", "Maybe"]

        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.send_resp(200, ~s({"event":{}}))
      end)

      assert {:ok, _} =
               XClient.DirectMessages.send("987654", "Free?",
                 quick_reply_options: ["Yes", "No", "Maybe"]
               )
    end
  end

  describe "destroy/2" do
    test "DELETEs direct_messages/events/destroy.json with id", %{bypass: bypass} do
      Bypass.expect_once(
        bypass,
        "DELETE",
        "/1.1/direct_messages/events/destroy.json",
        fn conn ->
          params = URI.decode_query(conn.query_string)
          assert params["id"] == "dm_event_id"

          conn |> Plug.Conn.send_resp(204, "")
        end
      )

      # 204 no content → {:ok, ""}
      assert {:ok, _} = XClient.DirectMessages.destroy("dm_event_id")
    end
  end

  describe "list/2" do
    test "GETs direct_messages/events/list.json", %{bypass: bypass} do
      response = %{
        "events" => [%{"id" => "1", "type" => "message_create"}],
        "next_cursor" => "abc123"
      }

      Bypass.expect_once(bypass, "GET", "/1.1/direct_messages/events/list.json", fn conn ->
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(response))
      end)

      assert {:ok, %{"events" => [_], "next_cursor" => "abc123"}} =
               XClient.DirectMessages.list(count: 20)
    end
  end

  describe "show/2" do
    test "GETs direct_messages/events/show.json with id", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/1.1/direct_messages/events/show.json", fn conn ->
        params = URI.decode_query(conn.query_string)
        assert params["id"] == "event_123"

        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.send_resp(200, ~s({"event":{"id":"event_123"}}))
      end)

      assert {:ok, %{"event" => %{"id" => "event_123"}}} = XClient.DirectMessages.show("event_123")
    end
  end
end

defmodule XClient.AccountTest do
  use ExUnit.Case, async: false

  import XClient.Test.Support

  setup :setup_bypass

  setup do
    put_test_credentials()
    on_exit(&delete_test_credentials/0)
    :ok
  end

  describe "verify_credentials/2" do
    test "GETs account/verify_credentials.json", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/1.1/account/verify_credentials.json", fn conn ->
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(user_fixture()))
      end)

      assert {:ok, %{"screen_name" => "elixirlang"}} = XClient.Account.verify_credentials()
    end

    test "passes opts as query params", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/1.1/account/verify_credentials.json", fn conn ->
        params = URI.decode_query(conn.query_string)
        assert params["skip_status"] == "true"

        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(user_fixture()))
      end)

      assert {:ok, _} = XClient.Account.verify_credentials(skip_status: true)
    end
  end

  describe "update_profile/2" do
    test "POSTs account/update_profile.json", %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/1.1/account/update_profile.json", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        params = URI.decode_query(body)
        assert params["name"] == "Jane Smith"
        assert params["description"] == "Elixir dev"

        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(user_fixture(%{"name" => "Jane Smith"})))
      end)

      assert {:ok, %{"name" => "Jane Smith"}} =
               XClient.Account.update_profile(name: "Jane Smith", description: "Elixir dev")
    end
  end

  describe "settings/1" do
    test "GETs account/settings.json", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/1.1/account/settings.json", fn conn ->
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.send_resp(200, ~s({"time_zone":{"name":"America/Los_Angeles"}}))
      end)

      assert {:ok, %{"time_zone" => _}} = XClient.Account.settings()
    end
  end
end

defmodule XClient.UsersTest do
  use ExUnit.Case, async: false

  import XClient.Test.Support

  setup :setup_bypass

  setup do
    put_test_credentials()
    on_exit(&delete_test_credentials/0)
    :ok
  end

  test "show/2 GETs users/show.json with screen_name", %{bypass: bypass} do
    Bypass.expect_once(bypass, "GET", "/1.1/users/show.json", fn conn ->
      params = URI.decode_query(conn.query_string)
      assert params["screen_name"] == "elixirlang"

      conn
      |> Plug.Conn.put_resp_header("content-type", "application/json")
      |> Plug.Conn.send_resp(200, Jason.encode!(user_fixture()))
    end)

    assert {:ok, %{"screen_name" => "elixirlang"}} = XClient.Users.show(screen_name: "elixirlang")
  end

  test "lookup/2 POSTs users/lookup.json", %{bypass: bypass} do
    Bypass.expect_once(bypass, "POST", "/1.1/users/lookup.json", fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      params = URI.decode_query(body)
      assert params["screen_name"] == "user1,user2"

      conn
      |> Plug.Conn.put_resp_header("content-type", "application/json")
      |> Plug.Conn.send_resp(200, Jason.encode!([user_fixture(), user_fixture()]))
    end)

    assert {:ok, [_, _]} = XClient.Users.lookup(screen_name: ["user1", "user2"])
  end

  test "search/3 GETs users/search.json with q", %{bypass: bypass} do
    Bypass.expect_once(bypass, "GET", "/1.1/users/search.json", fn conn ->
      params = URI.decode_query(conn.query_string)
      assert params["q"] == "elixir"
      assert params["count"] == "20"

      conn
      |> Plug.Conn.put_resp_header("content-type", "application/json")
      |> Plug.Conn.send_resp(200, Jason.encode!([user_fixture()]))
    end)

    assert {:ok, [_]} = XClient.Users.search("elixir", count: 20)
  end
end

defmodule XClient.APITest do
  use ExUnit.Case, async: false

  import XClient.Test.Support

  setup :setup_bypass

  setup do
    put_test_credentials()
    on_exit(&delete_test_credentials/0)
    :ok
  end

  describe "rate_limit_status/2" do
    test "GETs application/rate_limit_status.json", %{bypass: bypass} do
      response = %{
        "rate_limit_context" => %{"access_token" => "test"},
        "resources" => %{
          "statuses" => %{
            "/statuses/user_timeline" => %{"limit" => 900, "remaining" => 897, "reset" => 9_999}
          }
        }
      }

      Bypass.expect_once(
        bypass,
        "GET",
        "/1.1/application/rate_limit_status.json",
        fn conn ->
          conn
          |> Plug.Conn.put_resp_header("content-type", "application/json")
          |> Plug.Conn.send_resp(200, Jason.encode!(response))
        end
      )

      assert {:ok, %{"resources" => resources}} = XClient.API.rate_limit_status()
      assert Map.has_key?(resources, "statuses")
    end

    test "passes resources filter as query param", %{bypass: bypass} do
      Bypass.expect_once(
        bypass,
        "GET",
        "/1.1/application/rate_limit_status.json",
        fn conn ->
          params = URI.decode_query(conn.query_string)
          assert params["resources"] == "statuses,friends"

          conn
          |> Plug.Conn.put_resp_header("content-type", "application/json")
          |> Plug.Conn.send_resp(200, ~s({"resources":{}}))
        end
      )

      assert {:ok, _} = XClient.API.rate_limit_status(resources: "statuses,friends")
    end
  end
end
