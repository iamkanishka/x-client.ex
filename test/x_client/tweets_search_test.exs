defmodule XClient.TweetsTest do
  use ExUnit.Case, async: false

  import XClient.Test.Support

  alias XClient.Client

  setup :setup_bypass

  setup do
    put_test_credentials()
    on_exit(&delete_test_credentials/0)
    :ok
  end

  describe "update/3 — post tweet" do
    test "posts to statuses/update.json with status param", %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/1.1/statuses/update.json", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        assert URI.decode_query(body)["status"] == "Hello, X!"

        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(tweet_fixture(%{"text" => "Hello, X!"})))
      end)

      assert {:ok, %{"text" => "Hello, X!"}} = XClient.Tweets.update("Hello, X!")
    end

    test "accepts client as first argument (multi-account form)", %{bypass: bypass} do
      client = test_client()

      Bypass.expect_once(bypass, "POST", "/1.1/statuses/update.json", fn conn ->
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(tweet_fixture()))
      end)

      assert {:ok, _} = XClient.Tweets.update(client, "Multi-account tweet")
    end

    test "includes media_ids as comma-joined string", %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/1.1/statuses/update.json", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        params = URI.decode_query(body)
        assert params["media_ids"] == "aaa,bbb"

        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(tweet_fixture()))
      end)

      assert {:ok, _} = XClient.Tweets.update("With media", media_ids: ["aaa", "bbb"])
    end

    test "includes in_reply_to_status_id when provided", %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/1.1/statuses/update.json", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        params = URI.decode_query(body)
        assert params["in_reply_to_status_id"] == "999"

        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(tweet_fixture()))
      end)

      assert {:ok, _} = XClient.Tweets.update("@user reply", in_reply_to_status_id: "999")
    end
  end

  describe "destroy/3" do
    test "posts to statuses/destroy/:id.json", %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/1.1/statuses/destroy/123.json", fn conn ->
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(tweet_fixture()))
      end)

      assert {:ok, _} = XClient.Tweets.destroy("123")
    end
  end

  describe "retweet/3" do
    test "posts to statuses/retweet/:id.json", %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/1.1/statuses/retweet/456.json", fn conn ->
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(tweet_fixture()))
      end)

      assert {:ok, _} = XClient.Tweets.retweet("456")
    end
  end

  describe "unretweet/3" do
    test "posts to statuses/unretweet/:id.json", %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/1.1/statuses/unretweet/456.json", fn conn ->
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(tweet_fixture()))
      end)

      assert {:ok, _} = XClient.Tweets.unretweet("456")
    end
  end

  describe "show/3" do
    test "GETs statuses/show.json with id param", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/1.1/statuses/show.json", fn conn ->
        params = URI.decode_query(conn.query_string)
        assert params["id"] == "789"

        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(tweet_fixture(%{"id_string" => "789"})))
      end)

      assert {:ok, %{"id_string" => "789"}} = XClient.Tweets.show("789")
    end
  end

  describe "lookup/3" do
    test "posts to statuses/lookup.json with comma-joined ids", %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/1.1/statuses/lookup.json", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        params = URI.decode_query(body)
        assert params["id"] == "1,2,3"

        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!([tweet_fixture(), tweet_fixture()]))
      end)

      assert {:ok, [_, _]} = XClient.Tweets.lookup(["1", "2", "3"])
    end
  end

  describe "user_timeline/2" do
    test "GETs statuses/user_timeline.json with screen_name", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/1.1/statuses/user_timeline.json", fn conn ->
        params = URI.decode_query(conn.query_string)
        assert params["screen_name"] == "elixirlang"
        assert params["count"] == "50"

        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!([tweet_fixture()]))
      end)

      assert {:ok, [_]} = XClient.Tweets.user_timeline(screen_name: "elixirlang", count: 50)
    end
  end

  describe "retweeters_ids/3" do
    test "GETs statuses/retweeters/ids.json", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/1.1/statuses/retweeters/ids.json", fn conn ->
        params = URI.decode_query(conn.query_string)
        assert params["id"] == "42"

        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{"ids" => ["1", "2"]}))
      end)

      assert {:ok, %{"ids" => ["1", "2"]}} = XClient.Tweets.retweeters_ids("42")
    end
  end
end

defmodule XClient.SearchTest do
  use ExUnit.Case, async: false

  import XClient.Test.Support

  setup :setup_bypass

  setup do
    put_test_credentials()
    on_exit(&delete_test_credentials/0)
    :ok
  end

  describe "tweets/3" do
    test "GETs search/tweets.json with q param", %{bypass: bypass} do
      result = %{
        "statuses" => [tweet_fixture()],
        "search_metadata" => %{"count" => 1, "max_id" => 123}
      }

      Bypass.expect_once(bypass, "GET", "/1.1/search/tweets.json", fn conn ->
        params = URI.decode_query(conn.query_string)
        assert params["q"] == "elixir lang"
        assert params["count"] == "100"
        assert params["result_type"] == "recent"

        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(result))
      end)

      assert {:ok, %{"statuses" => [_], "search_metadata" => _}} =
               XClient.Search.tweets("elixir lang", count: 100, result_type: "recent")
    end

    test "does not include nil opts in query string", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/1.1/search/tweets.json", fn conn ->
        params = URI.decode_query(conn.query_string)
        refute Map.has_key?(params, "max_id")

        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{"statuses" => []}))
      end)

      assert {:ok, _} = XClient.Search.tweets("test", max_id: nil)
    end
  end
end

defmodule XClient.FavoritesTest do
  use ExUnit.Case, async: false

  import XClient.Test.Support

  setup :setup_bypass

  setup do
    put_test_credentials()
    on_exit(&delete_test_credentials/0)
    :ok
  end

  test "create/3 posts to favorites/create.json with id", %{bypass: bypass} do
    Bypass.expect_once(bypass, "POST", "/1.1/favorites/create.json", fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      assert URI.decode_query(body)["id"] == "555"

      conn
      |> Plug.Conn.put_resp_header("content-type", "application/json")
      |> Plug.Conn.send_resp(200, Jason.encode!(tweet_fixture()))
    end)

    assert {:ok, _} = XClient.Favorites.create("555")
  end

  test "destroy/3 posts to favorites/destroy.json with id", %{bypass: bypass} do
    Bypass.expect_once(bypass, "POST", "/1.1/favorites/destroy.json", fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      assert URI.decode_query(body)["id"] == "555"

      conn
      |> Plug.Conn.put_resp_header("content-type", "application/json")
      |> Plug.Conn.send_resp(200, Jason.encode!(tweet_fixture()))
    end)

    assert {:ok, _} = XClient.Favorites.destroy("555")
  end

  test "list/2 GETs favorites/list.json", %{bypass: bypass} do
    Bypass.expect_once(bypass, "GET", "/1.1/favorites/list.json", fn conn ->
      params = URI.decode_query(conn.query_string)
      assert params["screen_name"] == "elixirlang"

      conn
      |> Plug.Conn.put_resp_header("content-type", "application/json")
      |> Plug.Conn.send_resp(200, Jason.encode!([tweet_fixture()]))
    end)

    assert {:ok, [_]} = XClient.Favorites.list(screen_name: "elixirlang")
  end
end

defmodule XClient.TrendsTest do
  use ExUnit.Case, async: false

  import XClient.Test.Support

  setup :setup_bypass

  setup do
    put_test_credentials()
    on_exit(&delete_test_credentials/0)
    :ok
  end

  test "place/3 GETs trends/place.json with WOEID", %{bypass: bypass} do
    trends_response = [
      %{
        "trends" => [%{"name" => "#Elixir", "tweet_volume" => 10_000}],
        "as_of" => "2024-01-01T00:00:00Z",
        "locations" => [%{"name" => "Worldwide", "woeid" => 1}]
      }
    ]

    Bypass.expect_once(bypass, "GET", "/1.1/trends/place.json", fn conn ->
      params = URI.decode_query(conn.query_string)
      assert params["id"] == "1"

      conn
      |> Plug.Conn.put_resp_header("content-type", "application/json")
      |> Plug.Conn.send_resp(200, Jason.encode!(trends_response))
    end)

    assert {:ok, [%{"trends" => [_]}]} = XClient.Trends.place(1)
  end

  test "available/1 GETs trends/available.json", %{bypass: bypass} do
    Bypass.expect_once(bypass, "GET", "/1.1/trends/available.json", fn conn ->
      conn
      |> Plug.Conn.put_resp_header("content-type", "application/json")
      |> Plug.Conn.send_resp(200, Jason.encode!([%{"name" => "Worldwide", "woeid" => 1}]))
    end)

    assert {:ok, [%{"woeid" => 1}]} = XClient.Trends.available()
  end

  test "closest/2 GETs trends/closest.json with lat/long", %{bypass: bypass} do
    Bypass.expect_once(bypass, "GET", "/1.1/trends/closest.json", fn conn ->
      params = URI.decode_query(conn.query_string)
      assert params["lat"] == "37.781157"
      assert params["long"] == "-122.39872"

      conn
      |> Plug.Conn.put_resp_header("content-type", "application/json")
      |> Plug.Conn.send_resp(200, Jason.encode!([%{"name" => "San Francisco", "woeid" => 12}]))
    end)

    assert {:ok, [%{"name" => "San Francisco"}]} =
             XClient.Trends.closest(lat: 37.781157, long: -122.39872)
  end
end
