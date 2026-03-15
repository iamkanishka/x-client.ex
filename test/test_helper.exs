ExUnit.start()

# Ensure Bypass is started so HTTP integration tests can intercept requests
Application.ensure_all_started(:bypass)
