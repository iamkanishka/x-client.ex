defmodule XClient.Media do
  @moduledoc """
  Media upload operations for X API v1.1.

  Supports simple base64 uploads (images < 5 MB) and chunked INIT/APPEND/FINALIZE
  uploads for large files (GIFs up to 15 MB, videos up to 512 MB).

  ## Supported MIME types

    - `image/jpeg`, `image/png`, `image/gif`, `image/webp`
    - `video/mp4`, `video/quicktime`

  ## Examples

      # Upload an image
      {:ok, media} = XClient.Media.upload("priv/photo.jpg")
      {:ok, tweet} = XClient.Tweets.update("Check this!", media_ids: [media["media_id_string"]])

      # Upload with alt text (accessibility)
      {:ok, media} = XClient.Media.upload("priv/photo.jpg",
        alt_text: "A sunset over the ocean")

      # Upload a video (chunked automatically for large files)
      {:ok, media} = XClient.Media.upload("priv/clip.mp4",
        media_category: "tweet_video")
  """

  alias XClient.{Client, Error, HTTP}

  @upload_url "https://upload.x.com/1.1"

  # Files larger than this threshold use chunked upload
  @chunk_threshold 5 * 1024 * 1024
  # Each APPEND chunk is at most 5 MB
  @chunk_size 5 * 1024 * 1024
  # Maximum wait time for video processing before giving up (5 minutes)
  @max_processing_wait_ms 5 * 60 * 1000

  @type upload_opts :: [
          media_type: String.t(),
          media_category: String.t(),
          additional_owners: [String.t()],
          alt_text: String.t()
        ]

  @type response :: {:ok, map()} | {:error, Error.t()}

  ## ── Public API ──────────────────────────────────────────────────────────────

  @doc """
  Uploads media to X. Automatically selects simple or chunked upload based on size.

  `media` can be:
  - A file path (string) — the file is read and MIME type auto-detected
  - A binary blob — `:media_type` **must** be provided in `opts`

  ## Options

    - `:media_type` – MIME type string; required for binary blobs, auto-detected for paths
    - `:media_category` – `"tweet_image"`, `"tweet_gif"`, `"tweet_video"`, `"dm_image"`, etc.
    - `:additional_owners` – list of user ID strings who can also use the media
    - `:alt_text` – accessibility alt text (max 1000 chars)

  ## Example

      {:ok, media} = XClient.Media.upload("priv/photo.jpg", alt_text: "A cute cat")
      media_id = media["media_id_string"]
  """
  @spec upload(String.t() | binary(), upload_opts(), Client.t() | nil) :: response()
  def upload(media, opts \\ [], client \\ nil)

  def upload(path, opts, client) when is_binary(path) and byte_size(path) < 4096 do
    if File.exists?(path) do
      case File.read(path) do
        {:ok, data} ->
          media_type = Keyword.get(opts, :media_type) || detect_media_type(path)
          upload_binary(data, media_type, opts, client)

        {:error, reason} ->
          {:error, %Error{message: "Could not read file #{inspect(path)}: #{reason}"}}
      end
    else
      # Treat as raw binary data (short strings aren't valid paths anyway)
      upload_raw_binary(path, opts, client)
    end
  end

  def upload(binary, opts, client) when is_binary(binary) do
    upload_raw_binary(binary, opts, client)
  end

  @doc """
  Forces a chunked upload regardless of file size. Useful for pre-splitting control.

  Prefer `upload/3` which auto-selects the appropriate strategy.
  """
  @spec chunked_upload(String.t(), upload_opts(), Client.t() | nil) :: response()
  def chunked_upload(path, opts \\ [], client \\ nil) when is_binary(path) do
    with {:ok, data} <- File.read(path),
         media_type <- Keyword.get(opts, :media_type) || detect_media_type(path) do
      do_chunked_upload(data, media_type, opts, client)
    else
      {:error, reason} -> {:error, %Error{message: "Could not read #{inspect(path)}: #{reason}"}}
    end
  end

  @doc """
  Polls the processing status of an uploaded video or GIF.

  Returns the media object with a `"processing_info"` key containing
  `"state"` one of: `"pending"`, `"in_progress"`, `"succeeded"`, `"failed"`.

  ## Example

      {:ok, status} = XClient.Media.upload_status("9876543210")
      status["processing_info"]["state"]  #=> "succeeded"
  """
  @spec upload_status(String.t(), Client.t() | nil) :: response()
  def upload_status(media_id, client \\ nil) when is_binary(media_id) do
    HTTP.get("media/upload.json", %{command: "STATUS", media_id: media_id}, client,
      base_url: @upload_url
    )
  end

  @doc """
  Attaches alt text metadata to an already-uploaded media object.

  Alt text is truncated to 1000 characters if longer.

  ## Example

      {:ok, _} = XClient.Media.add_metadata("9876543210", "A photo of the Eiffel Tower")
  """
  @spec add_metadata(String.t(), String.t(), Client.t() | nil) :: response()
  def add_metadata(media_id, alt_text, client \\ nil)
      when is_binary(media_id) and is_binary(alt_text) do
    body =
      Jason.encode!(%{
        "media_id" => media_id,
        "alt_text" => %{"text" => String.slice(alt_text, 0, 1000)}
      })

    HTTP.post_json("media/metadata/create.json", body, client, base_url: @upload_url)
  end

  ## ── Private: upload strategies ──────────────────────────────────────────────

  defp upload_raw_binary(binary, opts, client) do
    case Keyword.get(opts, :media_type) do
      nil ->
        {:error, %Error{message: "`:media_type` is required when uploading a raw binary blob."}}

      media_type ->
        upload_binary(binary, media_type, opts, client)
    end
  end

  defp upload_binary(data, media_type, opts, client) do
    if byte_size(data) > @chunk_threshold do
      do_chunked_upload(data, media_type, opts, client)
    else
      do_simple_upload(data, media_type, opts, client)
    end
  end

  defp do_simple_upload(data, _media_type, opts, client) do
    media_category = Keyword.get(opts, :media_category)
    additional_owners = Keyword.get(opts, :additional_owners)
    alt_text = Keyword.get(opts, :alt_text)

    params =
      %{media_data: Base.encode64(data)}
      |> maybe_put(:media_category, media_category)
      |> maybe_put(:additional_owners, owners_string(additional_owners))

    with {:ok, result} <- HTTP.post("media/upload.json", params, client, base_url: @upload_url) do
      maybe_add_metadata(result, alt_text, client)
    end
  end

  defp do_chunked_upload(data, media_type, opts, client) do
    media_category = Keyword.get(opts, :media_category)
    additional_owners = Keyword.get(opts, :additional_owners)
    alt_text = Keyword.get(opts, :alt_text)

    with {:ok, media_id} <-
           init_upload(byte_size(data), media_type, media_category, additional_owners, client),
         :ok <- append_all_chunks(media_id, data, client),
         {:ok, result} <- finalize_upload(media_id, client) do
      maybe_add_metadata(result, alt_text, client)
    end
  end

  ## ── INIT / APPEND / FINALIZE ────────────────────────────────────────────────

  defp init_upload(total_bytes, media_type, media_category, additional_owners, client) do
    params =
      %{command: "INIT", total_bytes: total_bytes, media_type: media_type}
      |> maybe_put(:media_category, media_category)
      |> maybe_put(:additional_owners, owners_string(additional_owners))

    case HTTP.post("media/upload.json", params, client, base_url: @upload_url) do
      {:ok, %{"media_id_string" => media_id}} ->
        {:ok, media_id}

      {:ok, bad_response} ->
        {:error, %Error{message: "Unexpected INIT response: #{inspect(bad_response)}"}}

      {:error, _} = err ->
        err
    end
  end

  defp append_all_chunks(media_id, data, client) do
    data
    |> chunk_binary(@chunk_size)
    |> Enum.with_index()
    |> Enum.reduce_while(:ok, fn {chunk, index}, :ok ->
      case append_chunk(media_id, chunk, index, client) do
        :ok -> {:cont, :ok}
        error -> {:halt, error}
      end
    end)
  end

  defp append_chunk(media_id, chunk, segment_index, client) do
    params = %{
      command: "APPEND",
      media_id: media_id,
      media_data: Base.encode64(chunk),
      segment_index: segment_index
    }

    # APPEND returns 204 No Content on success; treat any 2xx as :ok
    case HTTP.post("media/upload.json", params, client, base_url: @upload_url) do
      {:ok, _} -> :ok
      {:error, _} = err -> err
    end
  end

  defp finalize_upload(media_id, client) do
    params = %{command: "FINALIZE", media_id: media_id}

    case HTTP.post("media/upload.json", params, client, base_url: @upload_url) do
      {:ok, %{"processing_info" => %{"state" => state} = processing_info} = result}
      when state in ["pending", "in_progress"] ->
        wait_for_processing(media_id, processing_info, client, 0)
        |> case do
          {:ok, _} -> {:ok, result}
          err -> err
        end

      {:ok, %{"processing_info" => %{"state" => "succeeded"}}} = ok ->
        ok

      {:ok, %{"processing_info" => %{"state" => "failed", "error" => error}}} ->
        {:error, %Error{message: "Media processing failed: #{inspect(error)}"}}

      {:ok, _} = ok ->
        ok

      {:error, _} = err ->
        err
    end
  end

  # ── Processing poll loop ──────────────────────────────────────────────────────

  @doc false
  defp wait_for_processing(_media_id, _info, _client, elapsed_ms)
       when elapsed_ms >= @max_processing_wait_ms do
    {:error,
     %Error{
       message: "Media processing timed out after #{div(@max_processing_wait_ms, 1000)}s"
     }}
  end

  defp wait_for_processing(media_id, processing_info, client, elapsed_ms) do
    wait_ms = Map.get(processing_info, "check_after_secs", 2) * 1_000
    Process.sleep(wait_ms)

    case upload_status(media_id, client) do
      {:ok, %{"processing_info" => %{"state" => "succeeded"} = new_info}} ->
        {:ok, new_info}

      {:ok, %{"processing_info" => %{"state" => "failed", "error" => error}}} ->
        {:error, %Error{message: "Media processing failed: #{inspect(error)}"}}

      {:ok, %{"processing_info" => new_info}} ->
        wait_for_processing(media_id, new_info, client, elapsed_ms + wait_ms)

      {:ok, result} ->
        # No processing_info in STATUS response means it's done
        {:ok, result}

      {:error, _} = err ->
        err
    end
  end

  ## ── Metadata helper ─────────────────────────────────────────────────────────

  # FIX: was silently discarding the add_metadata result and returning the
  # original upload result. Now we properly pipe the outcome.
  defp maybe_add_metadata(result, nil, _client), do: {:ok, result}

  defp maybe_add_metadata(result, alt_text, client) do
    media_id = result["media_id_string"]

    case add_metadata(media_id, alt_text, client) do
      {:ok, _} -> {:ok, result}
      {:error, _} = err -> err
    end
  end

  ## ── Utilities ───────────────────────────────────────────────────────────────

  defp chunk_binary(<<>>, _size), do: []

  defp chunk_binary(binary, size) do
    case binary do
      <<chunk::binary-size(size), rest::binary>> -> [chunk | chunk_binary(rest, size)]
      remaining -> [remaining]
    end
  end

  defp detect_media_type(path) do
    case MIME.from_path(path) do
      "application/octet-stream" -> ext_to_mime(Path.extname(path) |> String.downcase())
      mime -> mime
    end
  end

  defp ext_to_mime(".jpg"), do: "image/jpeg"
  defp ext_to_mime(".jpeg"), do: "image/jpeg"
  defp ext_to_mime(".png"), do: "image/png"
  defp ext_to_mime(".gif"), do: "image/gif"
  defp ext_to_mime(".webp"), do: "image/webp"
  defp ext_to_mime(".mp4"), do: "video/mp4"
  defp ext_to_mime(".mov"), do: "video/quicktime"
  defp ext_to_mime(_), do: "application/octet-stream"

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp owners_string(nil), do: nil
  defp owners_string(list), do: Enum.join(list, ",")
end
