defmodule XClient.Application do
  @moduledoc false
  # OTP Application callback. Starts the supervision tree.

  use Application

  require Logger

  @impl Application
  def start(_type, _args) do
    children = [
      {XClient.RateLimiter, []}
    ]

    opts = [strategy: :one_for_one, name: XClient.Supervisor]

    case Supervisor.start_link(children, opts) do
      {:ok, pid} ->
        maybe_warn_missing_config()
        {:ok, pid}

      error ->
        error
    end
  end

  # Warn (don't crash) at startup if credentials are unconfigured.
  # Hard validation happens per-request so the library is still usable in
  # test environments that set credentials dynamically via Application.put_env.
  defp maybe_warn_missing_config do
    case XClient.Config.validate!() do
      :ok ->
        :ok

      {:error, {:missing_config, keys}} ->
        Logger.warning(
          "[XClient] Missing configuration keys: #{inspect(keys)}. " <>
            "Set them in config/:x_client or via {:system, \"ENV_VAR\"} indirection."
        )
    end
  end
end
