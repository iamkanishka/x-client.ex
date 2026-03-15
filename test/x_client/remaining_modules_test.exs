defmodule XClient.FriendshipsTest do
  use ExUnit.Case, async: false

  import XClient.Test.Support

  setup :setup_bypass

  setup do
    put_test_credentials()
    on_exit(&delete_test_credentials/0)
    :ok
  end

  describe "create/2 — follow" do
    test "POSTs to friendships/create.json with screen_name", %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/1.1/friendships/create.json", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        params = URI.decode_query(body)
        assert params["screen_name"] == "elixirlang"

        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(user_fixture()))
      end)

      assert {:ok, %{"screen_name" => "elixirlang"}} =
               XClient.Friendships.create(screen_name: "elixirlang")
    end

    test "accepts user_id", %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/1.1/friendships/create.json", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        params = URI.decode_query(body)
        assert params["user_id"] == "123456"

        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(user_fixture()))
      end)

      assert {:ok, _} = XClient.Friendships.create(user_id: "123456")
    end
  end

  describe "destroy/2 — unfollow" do
    test "POSTs to friendships/destroy.json", %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/1.1/friendships/destroy.json", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        params = URI.decode_query(body)
        assert params["screen_name"] == "someone"

        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(user_fixture()))
      end)

      assert {:ok, _} = XClient.Friendships.destroy(screen_name: "someone")
    end
  end

  describe "show/2 — relationship" do
    test "GETs friendships/show.json with source and target", %{bypass: bypass} do
      relationship = %{
        "relationship" => %{
          "source" => %{"screen_name" => "user1", "following" => true},
          "target" => %{"screen_name" => "user2", "followed_by" => false}
        }
      }

      Bypass.expect_once(bypass, "GET", "/1.1/friendships/show.json", fn conn ->
        params = URI.decode_query(conn.query_string)
        assert params["source_screen_name"] == "user1"
        assert params["target_screen_name"] == "user2"

        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(relationship))
      end)

      assert {:ok, %{"relationship" => _}} =
               XClient.Friendships.show(
                 source_screen_name: "user1",
                 target_screen_name: "user2"
               )
    end
  end

  describe "followers_ids/2" do
    test "GETs followers/ids.json", %{bypass: bypass} do
      response = %{"ids" => ["1", "2", "3"], "next_cursor" => 0, "previous_cursor" => 0}

      Bypass.expect_once(bypass, "GET", "/1.1/followers/ids.json", fn conn ->
        params = URI.decode_query(conn.query_string)
        assert params["screen_name"] == "elixirlang"

        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(response))
      end)

      assert {:ok, %{"ids" => ["1", "2", "3"]}} =
               XClient.Friendships.followers_ids(screen_name: "elixirlang")
    end
  end

  describe "friends_ids/2" do
    test "GETs friends/ids.json", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/1.1/friends/ids.json", fn conn ->
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.send_resp(200, ~s({"ids":["10","20"],"next_cursor":0}))
      end)

      assert {:ok, %{"ids" => ["10", "20"]}} =
               XClient.Friendships.friends_ids(screen_name: "elixirlang")
    end
  end

  describe "followers_list/2" do
    test "GETs followers/list.json", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/1.1/followers/list.json", fn conn ->
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.send_resp(
          200,
          Jason.encode!(%{"users" => [user_fixture()], "next_cursor" => 0})
        )
      end)

      assert {:ok, %{"users" => [_]}} =
               XClient.Friendships.followers_list(screen_name: "elixirlang")
    end
  end
end

defmodule XClient.ListsTest do
  use ExUnit.Case, async: false

  import XClient.Test.Support

  setup :setup_bypass

  setup do
    put_test_credentials()
    on_exit(&delete_test_credentials/0)
    :ok
  end

  test "list/2 GETs lists/list.json", %{bypass: bypass} do
    Bypass.expect_once(bypass, "GET", "/1.1/lists/list.json", fn conn ->
      conn
      |> Plug.Conn.put_resp_header("content-type", "application/json")
      |> Plug.Conn.send_resp(200, Jason.encode!([%{"id_str" => "1", "name" => "Elixir devs"}]))
    end)

    assert {:ok, [%{"name" => "Elixir devs"}]} = XClient.Lists.list()
  end

  test "statuses/2 GETs lists/statuses.json with list_id", %{bypass: bypass} do
    Bypass.expect_once(bypass, "GET", "/1.1/lists/statuses.json", fn conn ->
      params = URI.decode_query(conn.query_string)
      assert params["list_id"] == "999"

      conn
      |> Plug.Conn.put_resp_header("content-type", "application/json")
      |> Plug.Conn.send_resp(200, Jason.encode!([tweet_fixture()]))
    end)

    assert {:ok, [_]} = XClient.Lists.statuses(list_id: "999")
  end

  test "members/2 GETs lists/members.json", %{bypass: bypass} do
    Bypass.expect_once(bypass, "GET", "/1.1/lists/members.json", fn conn ->
      conn
      |> Plug.Conn.put_resp_header("content-type", "application/json")
      |> Plug.Conn.send_resp(
        200,
        Jason.encode!(%{"users" => [user_fixture()], "next_cursor" => 0})
      )
    end)

    assert {:ok, %{"users" => [_]}} = XClient.Lists.members(list_id: "999")
  end

  test "memberships/2 GETs lists/memberships.json", %{bypass: bypass} do
    Bypass.expect_once(bypass, "GET", "/1.1/lists/memberships.json", fn conn ->
      conn
      |> Plug.Conn.put_resp_header("content-type", "application/json")
      |> Plug.Conn.send_resp(200, Jason.encode!(%{"lists" => [], "next_cursor" => 0}))
    end)

    assert {:ok, %{"lists" => []}} = XClient.Lists.memberships(screen_name: "elixirlang")
  end

  test "ownerships/2 GETs lists/ownerships.json", %{bypass: bypass} do
    Bypass.expect_once(bypass, "GET", "/1.1/lists/ownerships.json", fn conn ->
      conn
      |> Plug.Conn.put_resp_header("content-type", "application/json")
      |> Plug.Conn.send_resp(200, Jason.encode!(%{"lists" => [], "next_cursor" => 0}))
    end)

    assert {:ok, %{"lists" => []}} = XClient.Lists.ownerships(screen_name: "elixirlang")
  end

  test "subscriptions/2 GETs lists/subscriptions.json", %{bypass: bypass} do
    Bypass.expect_once(bypass, "GET", "/1.1/lists/subscriptions.json", fn conn ->
      conn
      |> Plug.Conn.put_resp_header("content-type", "application/json")
      |> Plug.Conn.send_resp(200, Jason.encode!(%{"lists" => [], "next_cursor" => 0}))
    end)

    assert {:ok, %{"lists" => []}} = XClient.Lists.subscriptions(screen_name: "elixirlang")
  end
end

defmodule XClient.GeoTest do
  use ExUnit.Case, async: false

  import XClient.Test.Support

  setup :setup_bypass

  setup do
    put_test_credentials()
    on_exit(&delete_test_credentials/0)
    :ok
  end

  test "id/2 GETs geo/id/:place_id.json", %{bypass: bypass} do
    place = %{
      "id" => "df51dec6f4ee2b2c",
      "full_name" => "Manhattan, NY",
      "country" => "United States",
      "place_type" => "city"
    }

    Bypass.expect_once(bypass, "GET", "/1.1/geo/id/df51dec6f4ee2b2c.json", fn conn ->
      conn
      |> Plug.Conn.put_resp_header("content-type", "application/json")
      |> Plug.Conn.send_resp(200, Jason.encode!(place))
    end)

    assert {:ok, %{"full_name" => "Manhattan, NY"}} = XClient.Geo.id("df51dec6f4ee2b2c")
  end
end

defmodule XClient.HelpTest do
  use ExUnit.Case, async: false

  import XClient.Test.Support

  setup :setup_bypass

  setup do
    put_test_credentials()
    on_exit(&delete_test_credentials/0)
    :ok
  end

  test "configuration/1 GETs help/configuration.json", %{bypass: bypass} do
    config = %{"photo_size_limit" => 3_145_728, "short_url_length" => 23}

    Bypass.expect_once(bypass, "GET", "/1.1/help/configuration.json", fn conn ->
      conn
      |> Plug.Conn.put_resp_header("content-type", "application/json")
      |> Plug.Conn.send_resp(200, Jason.encode!(config))
    end)

    assert {:ok, %{"photo_size_limit" => 3_145_728}} = XClient.Help.configuration()
  end

  test "languages/1 GETs help/languages.json", %{bypass: bypass} do
    Bypass.expect_once(bypass, "GET", "/1.1/help/languages.json", fn conn ->
      conn
      |> Plug.Conn.put_resp_header("content-type", "application/json")
      |> Plug.Conn.send_resp(
        200,
        Jason.encode!([%{"code" => "en", "name" => "English", "status" => "production"}])
      )
    end)

    assert {:ok, [%{"code" => "en"}]} = XClient.Help.languages()
  end

  test "privacy/1 GETs help/privacy.json", %{bypass: bypass} do
    Bypass.expect_once(bypass, "GET", "/1.1/help/privacy.json", fn conn ->
      conn
      |> Plug.Conn.put_resp_header("content-type", "application/json")
      |> Plug.Conn.send_resp(200, ~s({"privacy":"This is the privacy policy."}))
    end)

    assert {:ok, %{"privacy" => _}} = XClient.Help.privacy()
  end

  test "tos/1 GETs help/tos.json", %{bypass: bypass} do
    Bypass.expect_once(bypass, "GET", "/1.1/help/tos.json", fn conn ->
      conn
      |> Plug.Conn.put_resp_header("content-type", "application/json")
      |> Plug.Conn.send_resp(200, ~s({"tos":"These are the terms."}))
    end)

    assert {:ok, %{"tos" => _}} = XClient.Help.tos()
  end
end
