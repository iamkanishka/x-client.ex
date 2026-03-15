import Config

# ── Development overrides ──────────────────────────────────────────────────────
#
# Credentials for local development. These should never be committed to source
# control. Use a local `.env` file with `direnv` or `dotenv` to populate the
# environment variables, then reference them here.

config :x_client,
  consumer_key: System.get_env("X_CONSUMER_KEY"),
  consumer_secret: System.get_env("X_CONSUMER_SECRET"),
  access_token: System.get_env("X_ACCESS_TOKEN"),
  access_token_secret: System.get_env("X_ACCESS_TOKEN_SECRET"),

  # More aggressive retry in dev so rate limits don't stall manual testing.
  auto_retry: true,
  max_retries: 5,
  retry_base_delay_ms: 500
