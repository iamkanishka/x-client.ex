import Config

# ── Runtime configuration (production releases) ────────────────────────────────
#
# This file is evaluated at runtime when a release starts, NOT at compile time.
# Use System.fetch_env!/1 to hard-fail on missing secrets, or System.get_env/2
# with a default if the value is optional.
#
# This file is ignored by Mix in :dev and :test environments.

if config_env() == :prod do
  config :x_client,
    consumer_key: System.fetch_env!("X_CONSUMER_KEY"),
    consumer_secret: System.fetch_env!("X_CONSUMER_SECRET"),
    access_token: System.fetch_env!("X_ACCESS_TOKEN"),
    access_token_secret: System.fetch_env!("X_ACCESS_TOKEN_SECRET"),

    # Optional production overrides. Remove the comment to activate.
    # base_url: System.get_env("X_API_BASE_URL", "https://api.x.com/1.1"),
    # upload_url: System.get_env("X_UPLOAD_URL", "https://upload.x.com/1.1"),
    # max_retries: String.to_integer(System.get_env("X_MAX_RETRIES", "3")),
    # retry_base_delay_ms: String.to_integer(System.get_env("X_RETRY_BASE_DELAY_MS", "1000")),
    # request_timeout_ms: String.to_integer(System.get_env("X_REQUEST_TIMEOUT_MS", "30000"))
    auto_retry: true,
    max_retries: 3,
    retry_base_delay_ms: 1_000,
    request_timeout_ms: 30_000
end
