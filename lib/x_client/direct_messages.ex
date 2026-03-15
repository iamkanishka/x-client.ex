defmodule XClient.DirectMessages do
  @moduledoc """
  Direct Message operations — X API v1.1 `direct_messages/events/*`.

  Uses the newer event-based DM API (not the deprecated `direct_messages/new`).

  ## Rate Limits

  | Endpoint                              | User auth     | App-only      |
  |---------------------------------------|---------------|---------------|
  | POST direct_messages/events/new       | 1000 / 24 h   | 15000 / 24 h  |
  | DELETE direct_messages/events/destroy | —             | —             |
  | GET  direct_messages/events/list      | 15 / 15 min   | —             |
  | GET  direct_messages/events/show      | 15 / 15 min   | —             |

  ## Example

      # Send a plain DM
      {:ok, event} = XClient.DirectMessages.send("987654321", "Hey there!")

      # Send a DM with media
      {:ok, media} = XClient.Media.upload("image.jpg", media_category: "dm_image")
      {:ok, event} = XClient.DirectMessages.send("987654321", "Look at this!",
        media_id: media["media_id_string"])

      # Send with quick reply buttons
      {:ok, event} = XClient.DirectMessages.send("987654321", "Are you free?",
        quick_reply_options: ["Yes", "No", "Maybe"])
  """

  alias XClient.{Client, HTTP}

  @type response :: {:ok, term()} | {:error, XClient.Error.t()}

  @doc """
  Sends a new Direct Message to a user.

  ## Parameters

    - `recipient_id` – The user ID of the recipient (string)
    - `text` – The DM body text

  ## Options

    - `:media_id` – Media ID string to attach (upload first with `XClient.Media.upload/3`)
    - `:quick_reply_options` – List of label strings for quick-reply buttons (max 20, each max 36 chars)

  ## Examples

      {:ok, event} = XClient.DirectMessages.send("123456", "Hello!")

      {:ok, event} = XClient.DirectMessages.send("123456", "Pick one:",
        quick_reply_options: ["Option A", "Option B"])

  ## Rate Limit

  1000 per 24 hours (user), 15000 per 24 hours (app-only).
  """
  @spec send(String.t(), String.t(), keyword(), Client.t() | nil) :: response()
  def send(recipient_id, text, opts \\ [], client \\ nil)
      when is_binary(recipient_id) and is_binary(text) do
    body =
      Jason.encode!(%{
        "event" => %{
          "type" => "message_create",
          "message_create" => %{
            "target" => %{"recipient_id" => recipient_id},
            "message_data" => build_message_data(text, opts)
          }
        }
      })

    HTTP.post_json("direct_messages/events/new.json", body, client)
  end

  @doc """
  Deletes a Direct Message event.

  Note: a DM can only be deleted by its sender and within a given time window.

  ## Parameters

    - `id` – The DM event ID

  ## Example

      {:ok, _} = XClient.DirectMessages.destroy("123456789")
  """
  @spec destroy(String.t(), Client.t() | nil) :: {:ok, any()} | {:error, XClient.Error.t()}
  def destroy(id, client \\ nil) when is_binary(id) do
    HTTP.delete("direct_messages/events/destroy.json", [id: id], client)
  end

  @doc """
  Returns a list of Direct Message events (sent and received) for the authenticated user.

  Ordered newest first. Uses cursor-based pagination.

  ## Options

    - `:count` – Number of events to return (max 50, default 20)
    - `:cursor` – Pagination cursor from a previous response

  ## Examples

      {:ok, %{"events" => events, "next_cursor" => cursor}} =
        XClient.DirectMessages.list(count: 50)

      # Next page
      {:ok, %{"events" => more}} =
        XClient.DirectMessages.list(count: 50, cursor: cursor)

  ## Rate Limit

  15 per 15 minutes.
  """
  @spec list(keyword(), Client.t() | nil) :: response()
  def list(opts \\ [], client \\ nil) do
    params =
      opts
      |> Enum.reject(fn {_k, v} -> is_nil(v) end)
      |> Map.new()

    HTTP.get("direct_messages/events/list.json", params, client)
  end

  @doc """
  Returns a single Direct Message event.

  ## Parameters

    - `id` – The DM event ID

  ## Example

      {:ok, %{"event" => event}} = XClient.DirectMessages.show("123456789")

  ## Rate Limit

  15 per 15 minutes.
  """
  @spec show(String.t(), Client.t() | nil) :: response()
  def show(id, client \\ nil) when is_binary(id) do
    HTTP.get("direct_messages/events/show.json", [id: id], client)
  end

  # ── Private helpers ──────────────────────────────────────────────────────────

  defp build_message_data(text, opts) do
    %{"text" => text}
    |> maybe_put_attachment(Keyword.get(opts, :media_id))
    |> maybe_put_quick_reply(Keyword.get(opts, :quick_reply_options))
  end

  defp maybe_put_attachment(data, nil), do: data

  defp maybe_put_attachment(data, media_id) do
    Map.put(data, "attachment", %{
      "type" => "media",
      "media" => %{"id" => media_id}
    })
  end

  defp maybe_put_quick_reply(data, nil), do: data

  defp maybe_put_quick_reply(data, options) when is_list(options) do
    Map.put(data, "quick_reply", %{
      "type" => "options",
      "options" => Enum.map(options, fn label -> %{"label" => to_string(label)} end)
    })
  end
end
