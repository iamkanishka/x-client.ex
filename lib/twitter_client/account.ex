defmodule XClient.Account do
  @moduledoc """
  Account operations for X API v1.1.

  ## Rate Limits

  - GET account/verify_credentials: 75 per 15 minutes (user only)
  """

  alias XClient.HTTP

  @doc """
  Verifies the user's credentials and returns the authenticated user.

  ## Parameters

    - `opts` - Optional parameters
      - `:include_entities` - Include entities node
      - `:skip_status` - Exclude status from response
      - `:include_email` - Include email address (requires proper permissions)

  ## Examples

      {:ok, account} = XClient.Account.verify_credentials()
      {:ok, account} = XClient.Account.verify_credentials(include_email: true)

  ## Rate Limit

  75 requests per 15 minutes (user only)

  ## Returns

  The authenticated user object with additional account-level information.
  """
  def verify_credentials(opts \\ [], client \\ nil) do
    params = build_params(opts)
    HTTP.get("account/verify_credentials.json", params, client)
  end

  @doc """
  Updates the authenticated user's profile settings.

  ## Parameters

    - `opts` - Optional parameters
      - `:name` - Full name (max 50 characters)
      - `:url` - URL (max 100 characters)
      - `:location` - Location (max 30 characters)
      - `:description` - Bio (max 160 characters)
      - `:profile_link_color` - Hex color for links
      - `:include_entities` - Include entities node
      - `:skip_status` - Exclude status from response

  ## Examples

      {:ok, user} = XClient.Account.update_profile(
        name: "New Name",
        description: "New bio"
      )
  """
  def update_profile(opts \\ [], client \\ nil) do
    params = build_params(opts)
    HTTP.post("account/update_profile.json", params, client)
  end

  @doc """
  Updates the authenticated user's profile image.

  ## Parameters

    - `image_path` - Path to the image file or binary data
    - `opts` - Optional parameters
      - `:include_entities` - Include entities node
      - `:skip_status` - Exclude status from response

  ## Examples

      {:ok, user} = XClient.Account.update_profile_image("path/to/image.jpg")

  ## Notes

  Image must be:
  - Less than 700KB in size
  - GIF, JPG, or PNG format
  - Square aspect ratio recommended
  """
  def update_profile_image(image_path, opts \\ [], client \\ nil) when is_binary(image_path) do
    image_data =
      if File.exists?(image_path) do
        File.read!(image_path)
      else
        image_path
      end

    image_encoded = Base.encode64(image_data)

    params =
      opts
      |> Keyword.put(:image, image_encoded)
      |> build_params()

    HTTP.post("account/update_profile_image.json", params, client)
  end

  @doc """
  Updates the authenticated user's profile banner.

  ## Parameters

    - `banner_path` - Path to the banner image file or binary data
    - `opts` - Optional parameters
      - `:width` - Width of the banner upload in pixels
      - `:height` - Height of the banner upload in pixels
      - `:offset_left` - Number of pixels by which to offset the uploaded image
      - `:offset_top` - Number of pixels by which to offset the uploaded image

  ## Examples

      {:ok, _} = XClient.Account.update_profile_banner("path/to/banner.jpg")

  ## Notes

  Banner image must be:
  - Less than 5MB in size
  - JPG, PNG, or GIF format
  - Recommended dimensions: 1500x500 pixels
  """
  def update_profile_banner(banner_path, opts \\ [], client \\ nil) when is_binary(banner_path) do
    banner_data =
      if File.exists?(banner_path) do
        File.read!(banner_path)
      else
        banner_path
      end

    banner_encoded = Base.encode64(banner_data)

    params =
      opts
      |> Keyword.put(:banner, banner_encoded)
      |> build_params()

    HTTP.post("account/update_profile_banner.json", params, client)
  end

  @doc """
  Removes the authenticated user's profile banner.

  ## Examples

      {:ok, _} = XClient.Account.remove_profile_banner()
  """
  def remove_profile_banner(client \\ nil) do
    HTTP.post("account/remove_profile_banner.json", [], client)
  end

  @doc """
  Updates account settings for the authenticated user.

  ## Parameters

    - `opts` - Optional parameters
      - `:sleep_time_enabled` - Enable sleep time
      - `:start_sleep_time` - Sleep start hour (0-23)
      - `:end_sleep_time` - Sleep end hour (0-23)
      - `:time_zone` - Time zone name
      - `:trend_location_woeid` - WOEID for trend location
      - `:lang` - Interface language

  ## Examples

      {:ok, settings} = XClient.Account.update_settings(
        time_zone: "America/Los_Angeles"
      )
  """
  def update_settings(opts \\ [], client \\ nil) do
    params = build_params(opts)
    HTTP.post("account/settings.json", params, client)
  end

  @doc """
  Returns the authenticated user's account settings.

  ## Examples

      {:ok, settings} = XClient.Account.settings()
  """
  def settings(client \\ nil) do
    HTTP.get("account/settings.json", [], client)
  end

  # Helper functions

  defp build_params(opts) do
    opts
    |> Enum.map(fn {k, v} -> {k, format_value(v)} end)
    |> Enum.into(%{})
  end

  defp format_value(value) when is_boolean(value), do: to_string(value)
  defp format_value(value), do: value
end
