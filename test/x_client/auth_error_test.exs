defmodule XClient.AuthErrorTest do
  use ExUnit.Case, async: true

  alias XClient.{Auth, Client}
  import XClient.Test.Support

  describe "validate_credentials/1" do
    test "returns :ok when all fields are populated" do
      assert Auth.validate_credentials(test_client()) == :ok
    end

    test "returns error listing nil fields" do
      client = %Client{
        consumer_key: "ck",
        consumer_secret: nil,
        access_token: "at",
        access_token_secret: nil
      }

      assert {:error, {:missing_credentials, missing}} = Auth.validate_credentials(client)
      assert :consumer_secret in missing
      assert :access_token_secret in missing
      refute :consumer_key in missing
      refute :access_token in missing
    end

    test "treats empty string as missing" do
      client = %Client{
        consumer_key: "ck",
        consumer_secret: "",
        access_token: "at",
        access_token_secret: "ats"
      }

      assert {:error, {:missing_credentials, [:consumer_secret]}} =
               Auth.validate_credentials(client)
    end

    test "returns error with all four keys when none are set" do
      client = %Client{
        consumer_key: nil,
        consumer_secret: nil,
        access_token: nil,
        access_token_secret: nil
      }

      assert {:error, {:missing_credentials, missing}} = Auth.validate_credentials(client)
      assert length(missing) == 4
    end
  end

  describe "generate_nonce/0" do
    test "produces exactly 32 characters" do
      nonce = Auth.generate_nonce()
      assert String.length(nonce) == 32
    end

    test "contains only alphanumeric characters" do
      nonce = Auth.generate_nonce()
      assert nonce =~ ~r/^[a-zA-Z0-9]+$/
    end

    test "generates unique nonces across calls" do
      nonces = for _ <- 1..20, do: Auth.generate_nonce()
      assert length(Enum.uniq(nonces)) == 20
    end

    test "is random (not deterministic)" do
      n1 = Auth.generate_nonce()
      n2 = Auth.generate_nonce()
      assert n1 != n2
    end
  end

  describe "authorization_header/4" do
    test "returns a string starting with 'OAuth '" do
      client = test_client()

      header =
        Auth.authorization_header(
          :get,
          "https://api.x.com/1.1/statuses/show.json",
          [id: "123456789"],
          client
        )

      assert is_binary(header)
      assert String.starts_with?(header, "OAuth ")
    end

    test "accepts uppercase method strings" do
      client = test_client()

      header =
        Auth.authorization_header(
          "GET",
          "https://api.x.com/1.1/statuses/show.json",
          [],
          client
        )

      assert String.starts_with?(header, "OAuth ")
    end

    test "accepts atom methods" do
      client = test_client()

      header =
        Auth.authorization_header(
          :post,
          "https://api.x.com/1.1/statuses/update.json",
          [status: "Hello"],
          client
        )

      assert String.starts_with?(header, "OAuth ")
    end

    test "includes oauth_consumer_key" do
      client = test_client()

      header = Auth.authorization_header(:get, "https://api.x.com/1.1/test.json", [], client)

      assert header =~ "oauth_consumer_key"
    end

    test "two calls produce different nonces (different headers)" do
      client = test_client()
      url = "https://api.x.com/1.1/test.json"

      h1 = Auth.authorization_header(:get, url, [], client)
      h2 = Auth.authorization_header(:get, url, [], client)

      # Different nonces → different signatures
      assert h1 != h2
    end
  end
end

defmodule XClient.ErrorTest do
  use ExUnit.Case, async: true

  alias XClient.Error

  describe "Exception.message/1" do
    test "formats status and message" do
      error = %Error{status: 404, message: "Not Found"}
      msg = Exception.message(error)
      assert msg =~ "404"
      assert msg =~ "Not Found"
    end

    test "includes code when present" do
      error = %Error{status: 400, code: 187, message: "Duplicate status"}
      msg = Exception.message(error)
      assert msg =~ "187"
      assert msg =~ "Duplicate status"
    end

    test "works without status" do
      error = %Error{message: "Network timeout"}
      msg = Exception.message(error)
      assert msg =~ "Network timeout"
    end
  end

  describe "rate_limited/1" do
    test "sets status 429 and code 88" do
      error = Error.rate_limited(%{reset: 1_712_345_678})
      assert error.status == 429
      assert error.code == 88
    end

    test "message includes reset time" do
      ts = :os.system_time(:second) + 900
      error = Error.rate_limited(%{reset: ts})
      assert error.message =~ "Resets at"
    end

    test "handles nil reset gracefully" do
      error = Error.rate_limited(%{})
      assert error.status == 429
      assert error.message =~ "unknown time"
    end

    test "stores rate_limit_info" do
      info = %{limit: 900, remaining: 0, reset: 9_999_999_999}
      error = Error.rate_limited(info)
      assert error.rate_limit_info == info
    end
  end

  describe "from_body/2" do
    test "parses errors array with code" do
      body = %{"errors" => [%{"message" => "Rate limit exceeded", "code" => 88}]}
      error = Error.from_body(body, 429)

      assert error.status == 429
      assert error.code == 88
      assert error.message =~ "Rate limit exceeded"
      assert is_list(error.errors)
    end

    test "parses errors array without code" do
      body = %{"errors" => [%{"message" => "Sorry, that page does not exist"}]}
      error = Error.from_body(body, 404)

      assert error.status == 404
      assert error.message =~ "does not exist"
      assert is_nil(error.code)
    end

    test "joins multiple error messages with semicolon" do
      body = %{
        "errors" => [
          %{"message" => "First error", "code" => 1},
          %{"message" => "Second error", "code" => 2}
        ]
      }

      error = Error.from_body(body, 400)
      assert error.message =~ "First error"
      assert error.message =~ "Second error"
    end

    test "parses flat error string" do
      body = %{"error" => "Could not authenticate you."}
      error = Error.from_body(body, 401)

      assert error.status == 401
      assert error.message == "Could not authenticate you."
    end

    test "parses JSON binary body" do
      json = ~s({"errors":[{"message":"Bad request","code":32}]})
      error = Error.from_body(json, 400)

      assert error.status == 400
      assert error.message =~ "Bad request"
    end

    test "handles non-JSON binary gracefully" do
      error = Error.from_body("Internal Server Error", 500)
      assert error.status == 500
      assert error.message == "Internal Server Error"
    end
  end

  describe "network_error/1" do
    test "wraps a reason with no status" do
      error = Error.network_error(:timeout)
      assert is_nil(error.status)
      assert error.message =~ "timeout"
    end
  end
end
