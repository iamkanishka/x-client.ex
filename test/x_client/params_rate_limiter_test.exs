defmodule XClient.ParamsTest do
  use ExUnit.Case, async: true

  alias XClient.Params

  describe "build/1 with keyword list" do
    test "converts keyword list to map" do
      assert Params.build(screen_name: "elixirlang") == %{screen_name: "elixirlang"}
    end

    test "coerces true to string" do
      assert Params.build(include_rts: true) == %{include_rts: "true"}
    end

    test "coerces false to string" do
      assert Params.build(exclude_replies: false) == %{exclude_replies: "false"}
    end

    test "joins list values with commas" do
      assert Params.build(user_id: ["1", "2", "3"]) == %{user_id: "1,2,3"}
    end

    test "joins media_ids list" do
      assert Params.build(media_ids: ["aaa", "bbb"]) == %{media_ids: "aaa,bbb"}
    end

    test "drops nil values" do
      result = Params.build(screen_name: "x", user_id: nil, count: 10)
      assert result == %{screen_name: "x", count: 10}
      refute Map.has_key?(result, :user_id)
    end

    test "passes integers through unchanged" do
      assert Params.build(count: 50) == %{count: 50}
    end

    test "passes strings through unchanged" do
      assert Params.build(q: "elixir lang") == %{q: "elixir lang"}
    end

    test "empty list returns empty map" do
      assert Params.build([]) == %{}
    end
  end

  describe "build/1 with map" do
    test "handles map input" do
      assert Params.build(%{count: 10, trim_user: true}) == %{count: 10, trim_user: "true"}
    end

    test "drops nil values from maps" do
      result = Params.build(%{a: 1, b: nil})
      assert result == %{a: 1}
    end
  end

  describe "build/2 with extras" do
    test "merges extra key-value pairs" do
      result = Params.build([count: 10], id: "123")
      assert result == %{count: 10, id: "123"}
    end

    test "opts take precedence over extras on conflict" do
      # Keyword.merge: second arg wins
      result = Params.build([count: 20], count: 10)
      assert result[:count] == 20
    end

    test "works with boolean in extras" do
      result = Params.build([], trim_user: true)
      assert result == %{trim_user: "true"}
    end
  end
end

defmodule XClient.RateLimiterTest do
  use ExUnit.Case, async: false

  alias XClient.RateLimiter

  setup do
    RateLimiter.reset_all()
    :ok
  end

  describe "check_limit/1 — ETS-backed reads" do
    test "allows request when no limit info exists for endpoint" do
      assert RateLimiter.check_limit("statuses/user_timeline.json") == :ok
    end

    test "allows request when remaining > 0" do
      RateLimiter.update_limit("test/endpoint", %{
        limit: 900,
        remaining: 450,
        reset: :os.system_time(:second) + 900
      })

      assert RateLimiter.check_limit("test/endpoint") == :ok
    end

    test "allows request when remaining = 1" do
      RateLimiter.update_limit("test/endpoint", %{
        limit: 900,
        remaining: 1,
        reset: :os.system_time(:second) + 900
      })

      assert RateLimiter.check_limit("test/endpoint") == :ok
    end

    test "blocks request when remaining = 0 and window not yet reset" do
      future_reset = :os.system_time(:second) + 900

      RateLimiter.update_limit("test/endpoint", %{
        limit: 900,
        remaining: 0,
        reset: future_reset
      })

      assert RateLimiter.check_limit("test/endpoint") == {:error, :rate_limited}
    end

    test "allows request when remaining = 0 but reset has passed" do
      past_reset = :os.system_time(:second) - 5

      RateLimiter.update_limit("test/endpoint", %{
        limit: 900,
        remaining: 0,
        reset: past_reset
      })

      assert RateLimiter.check_limit("test/endpoint") == :ok
    end

    test "different endpoints tracked independently" do
      RateLimiter.update_limit("endpoint/a", %{
        remaining: 0,
        reset: :os.system_time(:second) + 900
      })

      assert RateLimiter.check_limit("endpoint/a") == {:error, :rate_limited}
      assert RateLimiter.check_limit("endpoint/b") == :ok
    end
  end

  describe "update_limit/2" do
    test "stores rate limit info" do
      info = %{limit: 900, remaining: 847, reset: 9_999_999_999}
      RateLimiter.update_limit("statuses/show.json", info)

      assert RateLimiter.get_limit_info("statuses/show.json") == info
    end

    test "overwrites existing info" do
      RateLimiter.update_limit("ep", %{remaining: 100, reset: 1})
      RateLimiter.update_limit("ep", %{remaining: 50, reset: 2})

      assert RateLimiter.get_limit_info("ep") == %{remaining: 50, reset: 2}
    end

    test "is asynchronous (cast) — does not block" do
      # Should return immediately
      result = RateLimiter.update_limit("ep", %{remaining: 1, reset: 99})
      assert result == :ok
    end
  end

  describe "get_limit_info/1" do
    test "returns nil when no info stored" do
      assert RateLimiter.get_limit_info("nonexistent/endpoint") == nil
    end

    test "returns stored info" do
      info = %{limit: 15, remaining: 14, reset: 1_234_567_890}
      RateLimiter.update_limit("trends/place.json", info)
      # Small sleep to let the cast be processed
      Process.sleep(10)
      assert RateLimiter.get_limit_info("trends/place.json") == info
    end
  end

  describe "reset_all/0" do
    test "clears all stored limits" do
      RateLimiter.update_limit("ep1", %{remaining: 0, reset: 999})
      RateLimiter.update_limit("ep2", %{remaining: 0, reset: 999})
      Process.sleep(10)

      RateLimiter.reset_all()

      assert RateLimiter.get_limit_info("ep1") == nil
      assert RateLimiter.get_limit_info("ep2") == nil
    end

    test "allows requests after reset even if previously blocked" do
      RateLimiter.update_limit("ep", %{remaining: 0, reset: :os.system_time(:second) + 999})
      Process.sleep(10)
      assert RateLimiter.check_limit("ep") == {:error, :rate_limited}

      RateLimiter.reset_all()
      assert RateLimiter.check_limit("ep") == :ok
    end
  end
end
