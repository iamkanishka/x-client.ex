defmodule XClient.Media do
  @moduledoc """
  Media upload operations for X API v1.1.

  Supports uploading images, videos, and GIFs with chunked upload for large files.

  ## Supported Media Types

  - Images: JPEG, PNG, GIF, WEBP
  - Videos: MP4
  - GIFs: Animated GIF

  ## Size Limits

  - Images: 5 MB
  - GIFs: 15 MB
  - Videos: 512 MB

  ## Examples

      # Simple image upload
      {:ok, media} = XClient.Media.upload("path/to/image.jpg")

      # Upload with category
      {:ok, media} = XClient.Media.upload("path/to/video.mp4",
        media_category: "tweet_video")

      # Upload from binary data
      {:ok, media} = XClient.Media.upload(image_binary,
        media_type: "image/png")
  """

  alias XClient.HTTP

  @upload_url "https://upload.x.com/1.1"

  # Chunk size for chunked uploads (5 MB)
  @chunk_size 5 * 1024 * 1024

  @doc """
  Uploads media to X.

  ## Parameters

    - `media` - File path or binary data
    - `opts` - Optional parameters
      - `:media_category` - Media category (tweet_image, tweet_gif, tweet_video, dm_image, dm_video, dm_gif)
      - `:media_type` - MIME type (auto-detected if not provided)
      - `:additional_owners` - List of user IDs who can use the media
      - `:alt_text` - Alt text for accessibility (up to 1000 characters)

  ## Examples

      {:ok, media} = XClient.Media.upload("image.jpg")
      {:ok, media} = XClient.Media.upload("video.mp4", media_category: "tweet_video")
      {:ok, media} = XClient.Media.upload(binary_data, media_type: "image/png")

  ## Returns

  `{:ok, media_object}` with media_id_string that can be used in tweets.
  """
  def upload(media, opts \\ [], client \\ nil)

  def upload(media, opts, client) when is_binary(media) do
    if File.exists?(media) do
      # Treat as a file path
      media_data = File.read!(media)
      media_type = Keyword.get(opts, :media_type) || detect_media_type(media)

      upload_binary(media_data, media_type, opts, client)
    else
      # Treat as raw binary data — media_type is mandatory
      media_type = Keyword.get(opts, :media_type)

      if media_type do
        upload_binary(media, media_type, opts, client)
      else
        {:error, %XClient.Error{message: "media_type is required when uploading binary data"}}
      end
    end
  end

  @doc """
  Uploads media using chunked upload (for large files).

  Automatically used for files larger than 5 MB.

  ## Parameters

    - `media_path` - Path to the media file
    - `opts` - Optional parameters (same as `upload/3`)

  ## Returns

  `{:ok, media_object}` with media_id_string.
  """
  def chunked_upload(media_path, opts \\ [], client \\ nil) do
    with {:ok, media_data} <- File.read(media_path),
         media_type <- Keyword.get(opts, :media_type) || detect_media_type(media_path),
         {:ok, media_id} <- init_upload(byte_size(media_data), media_type, opts, client),
         :ok <- append_chunks(media_id, media_data, client),
         {:ok, result} <- finalize_upload(media_id, client) do

      # Add alt text if provided
      case Keyword.get(opts, :alt_text) do
        nil -> {:ok, result}
        alt_text -> add_metadata(media_id, alt_text, client)
      end
    else
      {:error, _} = error ->
        error

      reason ->
        {:error, %XClient.Error{message: "Chunked upload failed: #{inspect(reason)}"}}
    end
  end

  @doc """
  Gets the processing status of uploaded media.

  Used for videos and GIFs that require processing.

  ## Parameters

    - `media_id` - The media ID to check

  ## Examples

      {:ok, status} = XClient.Media.upload_status("123456789")

  ## Returns

  Processing status with state: "pending", "in_progress", "failed", or "succeeded"
  """
  def upload_status(media_id, client \\ nil) do
    params = %{
      command: "STATUS",
      media_id: media_id
    }

    HTTP.get("media/upload.json", params, client, base_url: @upload_url)
  end

  @doc """
  Adds metadata (like alt text) to uploaded media.

  ## Parameters

    - `media_id` - The media ID
    - `alt_text` - Alt text for accessibility (up to 1000 characters)

  ## Examples

      {:ok, _} = XClient.Media.add_metadata("123456789", "A beautiful sunset")
  """
  def add_metadata(media_id, alt_text, client \\ nil) do
    body = Jason.encode!(%{
      media_id: media_id,
      alt_text: %{
        text: String.slice(alt_text, 0, 1000)
      }
    })

    HTTP.post_with_body(
      "media/metadata/create.json",
      body,
      [],
      client,
      base_url: @upload_url,
      content_type: "application/json"
    )
  end

  # Private functions

  defp upload_binary(media_data, media_type, opts, client) do
    size = byte_size(media_data)

    # Use chunked upload for files larger than 5 MB
    if size > @chunk_size do
      chunked_upload_binary(media_data, media_type, opts, client)
    else
      simple_upload(media_data, media_type, opts, client)
    end
  end

  defp simple_upload(media_data, media_type, opts, client) do
    media_category = Keyword.get(opts, :media_category)
    additional_owners = Keyword.get(opts, :additional_owners)

    # Encode as base64
    media_encoded = Base.encode64(media_data)

    params = %{
      media_data: media_encoded
    }

    params = if media_category, do: Map.put(params, :media_category, media_category), else: params
    params = if additional_owners, do: Map.put(params, :additional_owners, Enum.join(additional_owners, ",")), else: params

    case HTTP.post("media/upload.json", params, client, base_url: @upload_url) do
      {:ok, result} ->
        # Add alt text if provided
        case Keyword.get(opts, :alt_text) do
          nil -> {:ok, result}
          alt_text ->
            media_id = result["media_id_string"]
            add_metadata(media_id, alt_text, client)
            {:ok, result}
        end

      error -> error
    end
  end

  defp chunked_upload_binary(media_data, media_type, opts, client) do
    with {:ok, media_id} <- init_upload(byte_size(media_data), media_type, opts, client),
         :ok <- append_chunks(media_id, media_data, client),
         {:ok, result} <- finalize_upload(media_id, client) do

      # Add alt text if provided
      case Keyword.get(opts, :alt_text) do
        nil -> {:ok, result}
        alt_text ->
          add_metadata(media_id, alt_text, client)
          {:ok, result}
      end
    end
  end

  defp init_upload(total_bytes, media_type, opts, client) do
    media_category = Keyword.get(opts, :media_category)
    additional_owners = Keyword.get(opts, :additional_owners)

    params = %{
      command: "INIT",
      total_bytes: total_bytes,
      media_type: media_type
    }

    params = if media_category, do: Map.put(params, :media_category, media_category), else: params
    params = if additional_owners, do: Map.put(params, :additional_owners, Enum.join(additional_owners, ",")), else: params

    case HTTP.post("media/upload.json", params, client, base_url: @upload_url) do
      {:ok, %{"media_id_string" => media_id}} -> {:ok, media_id}
      {:ok, result} -> {:error, %XClient.Error{message: "Invalid INIT response: #{inspect(result)}"}}
      error -> error
    end
  end

  defp append_chunks(media_id, media_data, client) do
    chunks = chunk_binary(media_data, @chunk_size)

    chunks
    |> Enum.with_index()
    |> Enum.reduce_while(:ok, fn {chunk, index}, _acc ->
      case append_chunk(media_id, chunk, index, client) do
        :ok -> {:cont, :ok}
        error -> {:halt, error}
      end
    end)
  end

  defp append_chunk(media_id, chunk, segment_index, client) do
    # Encode chunk as base64
    media_encoded = Base.encode64(chunk)

    params = %{
      command: "APPEND",
      media_id: media_id,
      media_data: media_encoded,
      segment_index: segment_index
    }

    case HTTP.post("media/upload.json", params, client, base_url: @upload_url) do
      {:ok, _} -> :ok
      error -> error
    end
  end

  defp finalize_upload(media_id, client) do
    params = %{
      command: "FINALIZE",
      media_id: media_id
    }

    case HTTP.post("media/upload.json", params, client, base_url: @upload_url) do
      {:ok, result} ->
        # Check if processing is required
        case result["processing_info"] do
          nil ->
            {:ok, result}

          %{"state" => "pending"} = processing_info ->
            wait_for_processing(media_id, processing_info, client)

          %{"state" => "in_progress"} = processing_info ->
            wait_for_processing(media_id, processing_info, client)

          %{"state" => "succeeded"} ->
            {:ok, result}

          %{"state" => "failed", "error" => error} ->
            {:error, %XClient.Error{message: "Media processing failed: #{inspect(error)}"}}

          _ ->
            {:ok, result}
        end

      error -> error
    end
  end

  defp wait_for_processing(media_id, processing_info, client) do
    check_after = Map.get(processing_info, "check_after_secs", 1) * 1000
    Process.sleep(check_after)

    case upload_status(media_id, client) do
      {:ok, %{"processing_info" => %{"state" => "succeeded"}}} = result ->
        result

      {:ok, %{"processing_info" => %{"state" => "failed", "error" => error}}} ->
        {:error, %XClient.Error{message: "Media processing failed: #{inspect(error)}"}}

      {:ok, %{"processing_info" => processing_info}} ->
        wait_for_processing(media_id, processing_info, client)

      {:ok, result} ->
        {:ok, result}

      error ->
        error
    end
  end

  defp chunk_binary(binary, chunk_size) do
    do_chunk_binary(binary, chunk_size, [])
  end

  defp do_chunk_binary(<<>>, _chunk_size, acc) do
    Enum.reverse(acc)
  end

  defp do_chunk_binary(binary, chunk_size, acc) do
    case binary do
      <<chunk::binary-size(chunk_size), rest::binary>> ->
        do_chunk_binary(rest, chunk_size, [chunk | acc])

      remaining ->
        Enum.reverse([remaining | acc])
    end
  end

  defp detect_media_type(file_path) do
    case MIME.from_path(file_path) do
      "application/octet-stream" ->
        # Fallback to extension-based detection
        extension = Path.extname(file_path) |> String.downcase()
        extension_to_mime(extension)

      mime_type ->
        mime_type
    end
  end

  defp extension_to_mime(".jpg"), do: "image/jpeg"
  defp extension_to_mime(".jpeg"), do: "image/jpeg"
  defp extension_to_mime(".png"), do: "image/png"
  defp extension_to_mime(".gif"), do: "image/gif"
  defp extension_to_mime(".webp"), do: "image/webp"
  defp extension_to_mime(".mp4"), do: "video/mp4"
  defp extension_to_mime(".mov"), do: "video/quicktime"
  defp extension_to_mime(_), do: "application/octet-stream"
end
