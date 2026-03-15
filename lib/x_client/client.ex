defmodule XClient.Client do
  @moduledoc """
  Typed struct representing X API credentials.

  Prefer using `XClient.client/1` to create instances rather than building
  the struct directly, as it falls back to application config for missing fields.

  ## Fields

    - `:consumer_key` – OAuth consumer key
    - `:consumer_secret` – OAuth consumer secret
    - `:access_token` – OAuth access token
    - `:access_token_secret` – OAuth access token secret

  ## Example

      client = XClient.client(
        consumer_key: "CK",
        consumer_secret: "CS",
        access_token: "AT",
        access_token_secret: "ATS"
      )
  """

  @enforce_keys [:consumer_key, :consumer_secret, :access_token, :access_token_secret]
  defstruct [:consumer_key, :consumer_secret, :access_token, :access_token_secret]

  @type t :: %__MODULE__{
          consumer_key: String.t(),
          consumer_secret: String.t(),
          access_token: String.t(),
          access_token_secret: String.t()
        }
end
