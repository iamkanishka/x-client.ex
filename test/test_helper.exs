ExUnit.start()

# Ensure Bypass is started so HTTP integration tests can intercept requests
Application.ensure_all_started(:bypass)
# Ensure test-safe defaults are set at the start of the run.
# config/test.exs is loaded by mix but Application.delete_env in after blocks
# can drop keys back to the module default (true/3). We pin them here.
Application.put_env(:x_client, :auto_retry, false)
Application.put_env(:x_client, :max_retries, 0)
Application.put_env(:x_client, :retry_base_delay_ms, 0)
