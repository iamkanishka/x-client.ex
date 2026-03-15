defmodule XClient.Account do
  @moduledoc """
  Account settings and profile management — X API v1.1 `account/*`.

  ## Rate Limits

  | Endpoint                          | User auth   | App-only |
  |-----------------------------------|-------------|----------|
  | GET  account/verify_credentials   | 75 / 15 min | —        |
  | GET  account/settings             | 15 / 15 min | —        |
  | POST account/settings             | 15 / 15 min | —        |
  | POST account/update_profile       | 15 / 15 min | —        |
  | POST account/update_profile_image | 15 / 15 min | —        |
  | POST account/update_profile_banner| 15 / 15 min | —        |
  | POST account/remove_profile_banner| —           | —        |
  """

  alias XClient.{Client, HTTP, Params}

  @type response :: {:ok, term()} | {:error, XClient.Error.t()}

  @doc """
  Verifies the authenticating user's credentials and returns the user object.

  Useful to test that credentials are valid.

  ## Options

    - `:include_entities` – include entities node
    - `:skip_status` – exclude the user's most recent tweet
    - `:include_email` – include email address (requires special app permission)

  ## Example

      {:ok, user} = XClient.Account.verify_credentials()
      {:ok, user} = XClient.Account.verify_credentials(skip_status: true)

  ## Rate Limit

  75 per 15 minutes (user auth only).
  """
  @spec verify_credentials(keyword() | Client.t() | nil, keyword()) :: response()
  # Support `verify_credentials(client)` single-arg form
  def verify_credentials(client_or_opts \\ [], opts \\ [])

  def verify_credentials(%Client{} = client, opts) do
    HTTP.get("account/verify_credentials.json", Params.build(opts), client)
  end

  def verify_credentials(opts, []) when is_list(opts) do
    HTTP.get("account/verify_credentials.json", Params.build(opts), nil)
  end

  @doc """
  Returns the authenticated user's account settings.

  ## Example

      {:ok, settings} = XClient.Account.settings()

  ## Rate Limit

  15 per 15 minutes.
  """
  @spec settings(Client.t() | nil) :: response()
  def settings(client \\ nil) do
    HTTP.get("account/settings.json", [], client)
  end

  @doc """
  Updates the authenticated user's account settings.

  ## Options

    - `:sleep_time_enabled` – enable sleep time (no notifications during window)
    - `:start_sleep_time` – sleep start hour (0–23)
    - `:end_sleep_time` – sleep end hour (0–23)
    - `:time_zone` – Olson timezone name e.g. `"America/Los_Angeles"`
    - `:trend_location_woeid` – WOEID for trend location
    - `:lang` – Interface language code

  ## Example

      {:ok, settings} = XClient.Account.update_settings(
        time_zone: "America/New_York",
        lang: "en"
      )

  ## Rate Limit

  15 per 15 minutes.
  """
  @spec update_settings(keyword(), Client.t() | nil) :: response()
  def update_settings(opts \\ [], client \\ nil) do
    HTTP.post("account/settings.json", Params.build(opts), client)
  end

  @doc """
  Updates the authenticating user's profile fields.

  All fields are optional; omitted fields are left unchanged.

  ## Options

    - `:name` – Full name (max 50 chars)
    - `:url` – URL associated with profile (max 100 chars)
    - `:location` – City or country (max 30 chars)
    - `:description` – Bio (max 160 chars)
    - `:profile_link_color` – Hex color code for links (without `#`)
    - `:include_entities` – include entities in response
    - `:skip_status` – exclude most recent tweet from response

  ## Example

      {:ok, user} = XClient.Account.update_profile(
        name: "Jane Smith",
        description: "Elixir enthusiast | Coffee lover",
        location: "San Francisco, CA"
      )
  """
  @spec update_profile(keyword(), Client.t() | nil) :: response()
  def update_profile(opts \\ [], client \\ nil) do
    HTTP.post("account/update_profile.json", Params.build(opts), client)
  end

  @doc """
  Updates the authenticating user's profile image.

  Accepts a file path (reads and encodes the file) or raw binary image data.

  Supported formats: GIF, JPG, PNG. Max size: 700 KB.

  ## Parameters

    - `image` – File path string or binary image data

  ## Options

    - `:include_entities` – include entities in response
    - `:skip_status` – exclude most recent tweet

  ## Examples

      {:ok, user} = XClient.Account.update_profile_image("priv/avatar.jpg")

      image_binary = File.read!("priv/avatar.png")
      {:ok, user} = XClient.Account.update_profile_image(image_binary)
  """
  @spec update_profile_image(String.t() | binary(), keyword(), Client.t() | nil) :: response()
  def update_profile_image(image, opts \\ [], client \\ nil) when is_binary(image) do
    image_data =
      if File.exists?(image) do
        File.read!(image)
      else
        image
      end

    params = Params.build(opts, image: Base.encode64(image_data))
    HTTP.post("account/update_profile_image.json", params, client)
  end

  @doc """
  Updates the authenticating user's profile banner image.

  Accepts a file path or binary data. Recommended dimensions: 1500×500 px.
  Max size: 5 MB. Formats: JPG, PNG, GIF.

  ## Parameters

    - `banner` – File path string or binary image data

  ## Options

    - `:width` – Width of the uploaded image in pixels
    - `:height` – Height of the uploaded image in pixels
    - `:offset_left` – Horizontal offset in pixels
    - `:offset_top` – Vertical offset in pixels

  ## Example

      {:ok, _} = XClient.Account.update_profile_banner("priv/banner.jpg")
  """
  @spec update_profile_banner(String.t() | binary(), keyword(), Client.t() | nil) :: response()
  def update_profile_banner(banner, opts \\ [], client \\ nil) when is_binary(banner) do
    banner_data =
      if File.exists?(banner) do
        File.read!(banner)
      else
        banner
      end

    params = Params.build(opts, banner: Base.encode64(banner_data))
    HTTP.post("account/update_profile_banner.json", params, client)
  end

  @doc """
  Removes the authenticating user's profile banner.

  ## Example

      {:ok, _} = XClient.Account.remove_profile_banner()
  """
  @spec remove_profile_banner(Client.t() | nil) :: response()
  def remove_profile_banner(client \\ nil) do
    HTTP.post("account/remove_profile_banner.json", [], client)
  end
end
