defmodule XClient.HTTP do
  @moduledoc """
  Core HTTP layer for the X API client.

  Responsibilities:
  - OAuth 1.0a header generation per request
  - Pre-request rate limit checks (via ETS — non-blocking)
  - Post-response rate limit header ingestion
  - Exponential-backoff retry on 429 / transient errors
  - Telemetry instrumentation for every request
  - Structured `{:ok, body}` / `{:error, %XClient.Error{}}` return values

  ## Telemetry events

    - `[:x_client, :request, :start]`  — `%{method, url, endpoint}`
    - `[:x_client, :request, :stop]`   — `%{duration_us, status}`
    - `[:x_client, :request, :error]`  — `%{reason}` on network failures
  """

  alias XClient.{Auth, Client, Config, Error, RateLimiter}

  require Logger

  @type response :: {:ok, term()} | {:error, Error.t()}

  ## ── Public API ──────────────────────────────────────────────────────────────

  @doc "GET request. `params` go on the query string and into the OAuth signature."
  @spec get(String.t(), keyword() | map(), Client.t() | nil, keyword()) :: response()
  def get(endpoint, params \\ [], client \\ nil, opts \\ []) do
    request(:get, endpoint, params, nil, client, opts)
  end

  @doc "POST request with form-encoded body."
  @spec post(String.t(), keyword() | map(), Client.t() | nil, keyword()) :: response()
  def post(endpoint, params \\ [], client \\ nil, opts \\ []) do
    request(:post, endpoint, params, nil, client, opts)
  end

  @doc "POST request with a raw binary body (e.g., JSON or multipart)."
  @spec post_json(String.t(), String.t(), Client.t() | nil, keyword()) :: response()
  def post_json(endpoint, json_body, client \\ nil, opts \\ []) do
    opts = Keyword.put(opts, :content_type, "application/json")
    request(:post, endpoint, [], json_body, client, opts)
  end

  @doc "DELETE request."
  @spec delete(String.t(), keyword() | map(), Client.t() | nil, keyword()) :: response()
  def delete(endpoint, params \\ [], client \\ nil, opts \\ []) do
    request(:delete, endpoint, params, nil, client, opts)
  end

  # Keep legacy name for backwards compatibility
  @doc false
  def post_with_body(endpoint, body, params \\ [], client \\ nil, opts \\ []) do
    opts = Keyword.put_new(opts, :content_type, "application/json")
    request(:post, endpoint, params, body, client, opts)
  end

  ## ── Private: request pipeline ───────────────────────────────────────────────

  defp request(method, endpoint, params, body, client, opts) do
    client = resolve_client(client)
    retry_count = Keyword.get(opts, :_retry_count, 0)

    with :ok <- Auth.validate_credentials(client),
         :ok <- maybe_check_rate_limit(endpoint) do
      do_request(method, endpoint, params, body, client, opts, retry_count)
    end
  end

  defp do_request(method, endpoint, params, body, client, opts, retry_count) do
    base_url = Keyword.get(opts, :base_url, Config.base_url())
    url = build_url(base_url, endpoint)
    start_time = System.monotonic_time(:microsecond)

    :telemetry.execute(
      [:x_client, :request, :start],
      %{},
      %{method: method, url: url, endpoint: endpoint}
    )

    result = execute_request(method, url, params, body, client, opts)
    duration = System.monotonic_time(:microsecond) - start_time

    case result do
      {:ok, %{status: status} = response} when status in 200..299 ->
        ingest_rate_limit_headers(endpoint, response)

        :telemetry.execute(
          [:x_client, :request, :stop],
          %{duration_us: duration},
          %{method: method, url: url, endpoint: endpoint, status: status}
        )

        parse_response(response)

      {:ok, %{status: 429} = response} ->
        info = extract_rate_limit_info(response)

        :telemetry.execute(
          [:x_client, :request, :stop],
          %{duration_us: duration},
          %{method: method, url: url, endpoint: endpoint, status: 429}
        )

        handle_rate_limit_response(method, endpoint, params, body, client, opts, retry_count, info)

      {:ok, %{status: status, body: resp_body}} ->
        :telemetry.execute(
          [:x_client, :request, :stop],
          %{duration_us: duration},
          %{method: method, url: url, endpoint: endpoint, status: status}
        )

        {:error, Error.from_body(resp_body, status)}

      {:error, reason} ->
        :telemetry.execute(
          [:x_client, :request, :error],
          %{duration_us: duration},
          %{method: method, url: url, endpoint: endpoint, reason: reason}
        )

        {:error, Error.network_error(reason)}
    end
  end

  defp execute_request(method, url, params, body, client, opts) do
    headers = build_oauth_headers(method, url, params, body, client, opts)
    timeout = Config.request_timeout_ms()

    req_opts =
      [
        method: method,
        url: url,
        headers: headers,
        connect_options: [timeout: timeout],
        receive_timeout: timeout
      ]
      |> put_params_or_body(method, params, body)

    Req.request(req_opts)
  end

  # ── URL / header / body helpers ───────────────────────────────────────────────

  defp build_url(base_url, endpoint) do
    base = String.trim_trailing(base_url, "/")
    path = String.trim_leading(endpoint, "/")
    "#{base}/#{path}"
  end

  defp put_params_or_body(req_opts, method, params, nil) when method in [:get, :delete] do
    Keyword.put(req_opts, :params, params)
  end

  defp put_params_or_body(req_opts, _method, _params, body) when is_binary(body) do
    Keyword.put(req_opts, :body, body)
  end

  defp put_params_or_body(req_opts, _method, params, nil) do
    # POST/PUT with form-encoded body; params are both the form body and OAuth input
    Keyword.put(req_opts, :form, params)
  end

  defp build_oauth_headers(method, url, params, body, client, opts) do
    # For JSON body requests, only URL params go into the OAuth signature
    # For form POST, the form params go into the OAuth signature
    oauth_params =
      if is_binary(body) do
        # Raw body (JSON/multipart) — only query params in signature
        []
      else
        params
      end

    auth_value = Auth.authorization_header(method, url, oauth_params, client)
    content_type = Keyword.get(opts, :content_type)

    base_headers = [
      {"authorization", auth_value},
      {"accept", "application/json"},
      {"user-agent", "x-client.ex/#{version()}"}
    ]

    if content_type do
      [{"content-type", content_type} | base_headers]
    else
      base_headers
    end
  end

  # ── Response parsing ─────────────────────────────────────────────────────────

  defp parse_response(%{body: body}) when is_map(body) or is_list(body), do: {:ok, body}

  defp parse_response(%{body: body}) when is_binary(body) do
    case Jason.decode(body) do
      {:ok, decoded} -> {:ok, decoded}
      {:error, _} -> {:ok, body}
    end
  end

  defp parse_response(%{body: body}), do: {:ok, body}

  # ── Rate limiting ─────────────────────────────────────────────────────────────

  defp maybe_check_rate_limit(endpoint) do
    if Config.auto_retry?() do
      RateLimiter.check_limit(endpoint)
    else
      :ok
    end
  end

  defp ingest_rate_limit_headers(endpoint, response) do
    info = extract_rate_limit_info(response)

    if info[:remaining] do
      RateLimiter.update_limit(endpoint, info)
    end
  end

  defp extract_rate_limit_info(%Req.Response{headers: headers}) do
    %{
      limit: parse_int_header(headers, "x-rate-limit-limit"),
      remaining: parse_int_header(headers, "x-rate-limit-remaining"),
      reset: parse_int_header(headers, "x-rate-limit-reset")
    }
  end

  # Req 0.5 uses a map for headers
  defp parse_int_header(headers, key) when is_map(headers) do
    case Map.get(headers, key) do
      [value | _] -> parse_int(value)
      value when is_binary(value) -> parse_int(value)
      _ -> nil
    end
  end

  defp parse_int(value) when is_binary(value) do
    case Integer.parse(value) do
      {n, _} -> n
      :error -> nil
    end
  end

  defp parse_int(_), do: nil

  # ── Retry / backoff ──────────────────────────────────────────────────────────

  defp handle_rate_limit_response(
         method,
         endpoint,
         params,
         body,
         client,
         opts,
         retry_count,
         info
       ) do
    max = Config.max_retries()

    if Config.auto_retry?() && retry_count < max do
      delay = backoff_ms(retry_count)

      Logger.warning(
        "[XClient] Rate limited on #{inspect(endpoint)}. " <>
          "Retry #{retry_count + 1}/#{max} after #{delay}ms."
      )

      Process.sleep(delay)
      opts = Keyword.put(opts, :_retry_count, retry_count + 1)
      request(method, endpoint, params, body, client, opts)
    else
      {:error, Error.rate_limited(info)}
    end
  end

  # Exponential backoff with integer arithmetic: base * 2^n
  # 1s, 2s, 4s, 8s, …
  defp backoff_ms(retry_count) do
    Config.retry_base_delay_ms() * Integer.pow(2, retry_count)
  end

  # ── Client resolution ────────────────────────────────────────────────────────

  defp resolve_client(%Client{} = c), do: c

  defp resolve_client(nil) do
    %Client{
      consumer_key: Config.consumer_key(),
      consumer_secret: Config.consumer_secret(),
      access_token: Config.access_token(),
      access_token_secret: Config.access_token_secret()
    }
  end

  defp version do
    Application.spec(:x_client, :vsn) |> to_string()
  end
end
