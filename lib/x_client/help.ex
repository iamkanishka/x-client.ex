defmodule XClient.Help do
  @moduledoc """
  X API metadata and policy endpoints — `help/*`.

  **Bug fix:** `lib/twitter_client/help.ex` was an **empty file** in the
  original codebase. The module definition had been accidentally placed inside
  `test/test_helper.exs`, meaning it was never compiled into the library.

  ## Rate Limits

  | Endpoint              | User auth   | App-only   |
  |-----------------------|-------------|------------|
  | GET help/configuration| 15 / 15 min | 15 / 15 min|
  | GET help/languages    | 15 / 15 min | 15 / 15 min|
  | GET help/privacy      | 15 / 15 min | 15 / 15 min|
  | GET help/tos          | 15 / 15 min | 15 / 15 min|
  """

  alias XClient.{Client, HTTP}

  @type response :: {:ok, map() | list()} | {:error, XClient.Error.t()}

  @doc """
  Returns X's current configuration information.

  Useful for understanding current limits like `photo_size_limit`,
  `short_url_length`, and `max_media_per_upload`.

  ## Example

      {:ok, config} = XClient.Help.configuration()
      config["photo_size_limit"]  #=> 3145728

  ## Rate Limit

  15 per 15 minutes.
  """
  @spec configuration(Client.t() | nil) :: response()
  def configuration(client \\ nil) do
    HTTP.get("help/configuration.json", [], client)
  end

  @doc """
  Returns the list of languages supported by X along with their ISO 639-1 codes.

  ## Example

      {:ok, languages} = XClient.Help.languages()
      # [%{"code" => "en", "name" => "English", "status" => "production"}, ...]

  ## Rate Limit

  15 per 15 minutes.
  """
  @spec languages(Client.t() | nil) :: response()
  def languages(client \\ nil) do
    HTTP.get("help/languages.json", [], client)
  end

  @doc """
  Returns X's Privacy Policy as a string.

  ## Example

      {:ok, %{"privacy" => text}} = XClient.Help.privacy()

  ## Rate Limit

  15 per 15 minutes.
  """
  @spec privacy(Client.t() | nil) :: response()
  def privacy(client \\ nil) do
    HTTP.get("help/privacy.json", [], client)
  end

  @doc """
  Returns X's Terms of Service as a string.

  ## Example

      {:ok, %{"tos" => text}} = XClient.Help.tos()

  ## Rate Limit

  15 per 15 minutes.
  """
  @spec tos(Client.t() | nil) :: response()
  def tos(client \\ nil) do
    HTTP.get("help/tos.json", [], client)
  end
end
