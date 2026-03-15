defmodule XClient.RateLimiter do
  @moduledoc """
  GenServer that tracks X API rate limit windows per endpoint.

  State is stored in an ETS table (`__MODULE__`) so reads bypass the
  GenServer message queue entirely — only writes go through the process.

  ## Rate Limit Window Format

      %{
        limit: 900,       # total calls allowed per window
        remaining: 847,   # calls remaining
        reset: 1712345678 # unix timestamp when the window resets
      }

  ## Telemetry events emitted

    - `[:x_client, :rate_limit, :checked]` — every pre-request check
    - `[:x_client, :rate_limit, :blocked]` — when a request is blocked
    - `[:x_client, :rate_limit, :updated]` — after a successful response updates limits
  """

  use GenServer

  require Logger

  @table __MODULE__

  ## ── Public API ──────────────────────────────────────────────────────────────

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Returns `:ok` if the endpoint has capacity, `{:error, :rate_limited}` otherwise.

  This is a direct ETS read and does **not** block on the GenServer.
  """
  @spec check_limit(String.t()) :: :ok | {:error, :rate_limited}
  def check_limit(endpoint) do
    result =
      case :ets.lookup(@table, endpoint) do
        [] ->
          :ok

        [{^endpoint, %{remaining: remaining, reset: reset}}] when remaining <= 0 ->
          if :os.system_time(:second) >= reset do
            :ok
          else
            :rate_limited
          end

        [{^endpoint, _}] ->
          :ok
      end

    :telemetry.execute(
      [:x_client, :rate_limit, :checked],
      %{},
      %{endpoint: endpoint, result: result}
    )

    if result == :rate_limited do
      :telemetry.execute([:x_client, :rate_limit, :blocked], %{}, %{endpoint: endpoint})
      Logger.warning("[XClient] Rate limited on #{inspect(endpoint)}")
      {:error, :rate_limited}
    else
      :ok
    end
  end

  @doc """
  Asynchronously updates the stored rate limit info for an endpoint.

  Called after every successful response using the `X-Rate-Limit-*` headers.
  """
  @spec update_limit(String.t(), map()) :: :ok
  def update_limit(endpoint, info) when is_binary(endpoint) and is_map(info) do
    GenServer.cast(__MODULE__, {:update_limit, endpoint, info})
  end

  @doc "Returns the stored rate limit info for an endpoint, or `nil`."
  @spec get_limit_info(String.t()) :: map() | nil
  def get_limit_info(endpoint) do
    case :ets.lookup(@table, endpoint) do
      [{^endpoint, info}] -> info
      [] -> nil
    end
  end

  @doc "Clears all stored rate limit windows. Useful in tests."
  @spec reset_all() :: :ok
  def reset_all do
    GenServer.call(__MODULE__, :reset_all)
  end

  ## ── GenServer callbacks ─────────────────────────────────────────────────────

  @impl GenServer
  def init(_opts) do
    table = :ets.new(@table, [:named_table, :set, :public, read_concurrency: true])
    {:ok, %{table: table}}
  end

  @impl GenServer
  def handle_cast({:update_limit, endpoint, info}, state) do
    :ets.insert(@table, {endpoint, info})

    :telemetry.execute(
      [:x_client, :rate_limit, :updated],
      %{remaining: info[:remaining] || 0},
      %{endpoint: endpoint}
    )

    {:noreply, state}
  end

  @impl GenServer
  def handle_call(:reset_all, _from, state) do
    :ets.delete_all_objects(@table)
    {:reply, :ok, state}
  end
end
