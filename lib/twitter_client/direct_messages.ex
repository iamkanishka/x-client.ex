defmodule XClient.DirectMessages do
  @moduledoc """
  Direct Messages operations for X API v1.1.

  ## Rate Limits

  - POST direct_messages/events/new: 1000 per 24 hours (user), 15000 per 24 hours (app)
  """

  alias XClient.HTTP

  @doc """
  Sends a new direct message.

  ## Parameters

    - `recipient_id` - The ID of the recipient user
    - `text` - The message text
    - `opts` - Optional parameters
      - `:media_id` - Media ID to attach
      - `:quick_reply_options` - List of quick reply options

  ## Examples

      {:ok, message} = XClient.DirectMessages.send("123456", "Hello!")

      # With media
      {:ok, media} = XClient.Media.upload("image.jpg")
      {:ok, message} = XClient.DirectMessages.send(
        "123456",
        "Check this out!",
        media_id: media["media_id_string"]
      )

  ## Rate Limit

  1000 requests per 24 hours (user), 15000 per 24 hours (app)
  """
  def send(recipient_id, text, opts \\ [], client \\ nil) do
    message_create = %{
      "target" => %{
        "recipient_id" => recipient_id
      },
      "message_data" => build_message_data(text, opts)
    }

    event = %{
      "event" => %{
        "type" => "message_create",
        "message_create" => message_create
      }
    }

    body = Jason.encode!(event)

    HTTP.post_with_body(
      "direct_messages/events/new.json",
      body,
      [],
      client,
      content_type: "application/json"
    )
  end

  @doc """
  Deletes a direct message.

  ## Parameters

    - `id` - The ID of the direct message to delete

  ## Examples

      {:ok, _} = XClient.DirectMessages.destroy("123456789")
  """
  def destroy(id, client \\ nil) do
    HTTP.delete("direct_messages/events/destroy.json", [id: id], client)
  end

  @doc """
  Returns a list of direct messages.

  ## Parameters

    - `opts` - Optional parameters
      - `:count` - Number of events to return (max 50)
      - `:cursor` - Cursor for pagination

  ## Examples

      {:ok, messages} = XClient.DirectMessages.list(count: 50)
  """
  def list(opts \\ [], client \\ nil) do
    params = build_params(opts)
    HTTP.get("direct_messages/events/list.json", params, client)
  end

  @doc """
  Returns a single direct message event.

  ## Parameters

    - `id` - The ID of the direct message

  ## Examples

      {:ok, message} = XClient.DirectMessages.show("123456789")
  """
  def show(id, client \\ nil) do
    HTTP.get("direct_messages/events/show.json", [id: id], client)
  end

  # Private helpers

  defp build_message_data(text, opts) do
    message_data = %{"text" => text}

    message_data =
      case Keyword.get(opts, :media_id) do
        nil -> message_data
        media_id -> Map.put(message_data, "attachment", %{
          "type" => "media",
          "media" => %{"id" => media_id}
        })
      end

    message_data =
      case Keyword.get(opts, :quick_reply_options) do
        nil -> message_data
        options -> Map.put(message_data, "quick_reply", %{
          "type" => "options",
          "options" => Enum.map(options, fn opt ->
            %{"label" => opt}
          end)
        })
      end

    message_data
  end

  defp build_params(opts) do
    opts
    |> Enum.map(fn {k, v} -> {k, format_value(v)} end)
    |> Enum.into(%{})
  end

  defp format_value(value), do: value
end
