import Config

# ── Test environment overrides ─────────────────────────────────────────────────
#
# Credentials are set to dummy values by default. Individual tests that need
# specific values should use Application.put_env/3 in their setup callbacks,
# and clean up with Application.delete_env/2 in on_exit.
#
# When using Bypass, tests override :base_url and :upload_url to point at the
# local Bypass port. See test/support/helpers.ex for the setup_bypass/1 helper.

config :x_client,
  consumer_key: "test_consumer_key",
  consumer_secret: "test_consumer_secret",
  access_token: "test_access_token",
  access_token_secret: "test_access_token_secret",

  # Disable retry in tests — tests should assert on the exact response.
  # Individual tests that exercise retry logic override this locally.
  auto_retry: false,
  max_retries: 0,
  retry_base_delay_ms: 0,

  # Short timeout — test mocks respond immediately.
  request_timeout_ms: 5_000
