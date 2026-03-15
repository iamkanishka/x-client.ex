import Config

# ── XClient default configuration ─────────────────────────────────────────────
#
# Override any of these in config/dev.exs, config/test.exs, or config/runtime.exs.
# For production, prefer config/runtime.exs with System.fetch_env!/1 so that
# secrets are never baked into compiled releases.

config :x_client,
  # OAuth 1.0a credentials.
  # Set to actual values here for local dev, or use {:system, "ENV_VAR"} for
  # environment-variable indirection (resolved at call-time, not compile-time).
  #
  # consumer_key:        "YOUR_CONSUMER_KEY",
  # consumer_secret:     "YOUR_CONSUMER_SECRET",
  # access_token:        "YOUR_ACCESS_TOKEN",
  # access_token_secret: "YOUR_ACCESS_TOKEN_SECRET",

  # API endpoints. Override only if pointing at a proxy or mock server.
  base_url: "https://api.x.com/1.1",
  upload_url: "https://upload.x.com/1.1",

  # Retry behaviour on 429 rate-limit responses.
  # The delay doubles each attempt: base_ms, base_ms*2, base_ms*4, …
  auto_retry: true,
  max_retries: 3,
  retry_base_delay_ms: 1_000,

  # HTTP request timeout in milliseconds.
  request_timeout_ms: 30_000
