defmodule XClient.RateLimiter do
  @moduledoc """
  Rate limiter for X API requests.

  Tracks rate limits per endpoint and prevents exceeding limits.
  """

  use GenServer

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Checks if a request to the endpoint is allowed.
  """
  def check_limit(endpoint) do
    GenServer.call(__MODULE__, {:check_limit, endpoint})
  end

  @doc """
  Updates the rate limit information for an endpoint.
  """
  def update_limit(endpoint, info) do
    GenServer.cast(__MODULE__, {:update_limit, endpoint, info})
  end

  @doc """
  Gets the current rate limit info for an endpoint.
  """
  def get_limit_info(endpoint) do
    GenServer.call(__MODULE__, {:get_limit_info, endpoint})
  end

  @doc """
  Resets all rate limit information.
  """
  def reset_all do
    GenServer.cast(__MODULE__, :reset_all)
  end

  # Server Callbacks

  @impl true
  def init(_opts) do
    # State: %{endpoint => %{limit: int, remaining: int, reset: timestamp}}
    {:ok, %{}}
  end

  @impl true
  def handle_call({:check_limit, endpoint}, _from, state) do
    case Map.get(state, endpoint) do
      nil ->
        # No rate limit info yet, allow the request
        {:reply, :ok, state}

      %{remaining: remaining, reset: reset} when remaining <= 0 ->
        current_time = :os.system_time(:second)

        if current_time >= reset do
          # Rate limit has reset
          {:reply, :ok, state}
        else
          # Still rate limited
          {:reply, {:error, :rate_limited}, state}
        end

      %{remaining: remaining} when remaining > 0 ->
        # Have remaining requests
        {:reply, :ok, state}

      _ ->
        # Unknown state, allow request
        {:reply, :ok, state}
    end
  end

  @impl true
  def handle_call({:get_limit_info, endpoint}, _from, state) do
    info = Map.get(state, endpoint)
    {:reply, info, state}
  end

  @impl true
  def handle_cast({:update_limit, endpoint, info}, state) do
    new_state = Map.put(state, endpoint, info)
    {:noreply, new_state}
  end

  @impl true
  def handle_cast(:reset_all, _state) do
    {:noreply, %{}}
  end
end
