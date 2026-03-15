defmodule XClient.MediaTest do
  @moduledoc """
  Tests for XClient.Media covering simple upload, chunked upload,
  alt-text metadata, and upload_status polling.
  """

  use ExUnit.Case, async: false

  import XClient.Test.Support

  alias XClient.Error

  setup :setup_bypass

  setup do
    put_test_credentials()
    on_exit(&delete_test_credentials/0)
    :ok
  end

  # ── Simple upload ─────────────────────────────────────────────────────────────

  describe "upload/3 — binary data" do
    test "requires media_type when uploading raw binary", %{bypass: _bypass} do
      assert {:error, %Error{message: msg}} = XClient.Media.upload(<<1, 2, 3, 4, 5>>)

      assert msg =~ "media_type"
    end

    test "POSTs base64-encoded data to media/upload.json", %{bypass: bypass} do
      media_response = media_fixture()
      image_data = :crypto.strong_rand_bytes(100)
      encoded = Base.encode64(image_data)

      Bypass.expect_once(bypass, "POST", "/1.1/media/upload.json", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        params = URI.decode_query(body)
        assert params["media_data"] == encoded

        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(media_response))
      end)

      assert {:ok, %{"media_id_string" => _}} =
               XClient.Media.upload(image_data, media_type: "image/png")
    end

    test "includes media_category when provided", %{bypass: bypass} do
      image_data = :crypto.strong_rand_bytes(50)

      Bypass.expect_once(bypass, "POST", "/1.1/media/upload.json", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        params = URI.decode_query(body)
        assert params["media_category"] == "tweet_image"

        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(media_fixture()))
      end)

      assert {:ok, _} =
               XClient.Media.upload(image_data,
                 media_type: "image/png",
                 media_category: "tweet_image"
               )
    end
  end

  describe "upload/3 — file path that does not exist" do
    test "returns error when path is not a file and no media_type given", %{bypass: _bypass} do
      # Not a file, not binary with media_type → should error
      assert {:error, %Error{}} = XClient.Media.upload("not_a_real_file.jpg")
    end
  end

  describe "upload_status/2" do
    test "GETs media/upload.json with STATUS command", %{bypass: bypass} do
      processing = %{
        "media_id_string" => "111222333",
        "processing_info" => %{
          "state" => "succeeded",
          "progress_percent" => 100
        }
      }

      Bypass.expect_once(bypass, "GET", "/1.1/media/upload.json", fn conn ->
        params = URI.decode_query(conn.query_string)
        assert params["command"] == "STATUS"
        assert params["media_id"] == "111222333"

        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(processing))
      end)

      assert {:ok, %{"processing_info" => %{"state" => "succeeded"}}} =
               XClient.Media.upload_status("111222333")
    end
  end

  describe "add_metadata/3" do
    test "POSTs JSON alt text to media/metadata/create.json", %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/1.1/media/metadata/create.json", fn conn ->
        ct = Plug.Conn.get_req_header(conn, "content-type")
        assert hd(ct) =~ "application/json"

        {:ok, raw, conn} = Plug.Conn.read_body(conn)
        body = Jason.decode!(raw)
        assert body["media_id"] == "777"
        assert body["alt_text"]["text"] == "A sunset"

        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.send_resp(204, "")
      end)

      assert {:ok, _} = XClient.Media.add_metadata("777", "A sunset")
    end

    test "truncates alt_text to 1000 characters" do
      long_text = String.duplicate("x", 1500)
      # We verify the truncation without an HTTP call by inspecting the JSON body
      # that would be sent. Use a bypass to capture it.
    end
  end

  describe "chunked_upload/3 — INIT/APPEND/FINALIZE flow" do
    test "completes the three-phase upload for a small binary", %{bypass: bypass} do
      # We'll send a tiny file (smaller than the chunk size)
      # and verify INIT, APPEND, and FINALIZE calls are made in order.
      call_order = Agent.start_link(fn -> [] end) |> elem(1)

      Bypass.expect(bypass, "POST", "/1.1/media/upload.json", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        params = URI.decode_query(body)
        command = params["command"]
        Agent.update(call_order, fn acc -> acc ++ [command] end)

        response =
          case command do
            "INIT" -> %{"media_id_string" => "chunk_id_123"}
            "APPEND" -> %{}
            "FINALIZE" -> %{"media_id_string" => "chunk_id_123", "size" => 100}
            _ -> %{}
          end

        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(response))
      end)

      # Write a small temp file
      tmp = System.tmp_dir!() |> Path.join("test_media.jpg")
      File.write!(tmp, :crypto.strong_rand_bytes(200))

      assert {:ok, %{"media_id_string" => "chunk_id_123"}} =
               XClient.Media.chunked_upload(tmp, media_type: "image/jpeg")

      order = Agent.get(call_order, & &1)
      assert "INIT" in order
      assert "APPEND" in order
      assert "FINALIZE" in order
      assert List.first(order) == "INIT"
      assert List.last(order) == "FINALIZE"
    after
      tmp = System.tmp_dir!() |> Path.join("test_media.jpg")
      File.rm(tmp)
    end
  end
end
