defmodule XClient.HTTP do
  @moduledoc """
  HTTP client for making requests to X API.
  """

  alias XClient.{Auth, Config, RateLimiter, Error}

  @doc """
  Makes a GET request to the X API.

  ## Parameters

    - `endpoint` - API endpoint path (e.g., "statuses/user_timeline.json")
    - `params` - Query parameters (keyword list or map)
    - `client` - Optional client credentials map
    - `opts` - Additional options

  ## Returns

    - `{:ok, response}` on success
    - `{:error, error}` on failure
  """
  def get(endpoint, params \\ [], client \\ nil, opts \\ []) do
    request(:get, endpoint, params, nil, client, opts)
  end

  @doc """
  Makes a POST request to the X API.
  """
  def post(endpoint, params \\ [], client \\ nil, opts \\ []) do
    request(:post, endpoint, params, nil, client, opts)
  end

  @doc """
  Makes a POST request with a body to the X API.
  """
  def post_with_body(endpoint, body, params \\ [], client \\ nil, opts \\ []) do
    request(:post, endpoint, params, body, client, opts)
  end

  @doc """
  Makes a DELETE request to the X API.
  """
  def delete(endpoint, params \\ [], client \\ nil, opts \\ []) do
    request(:delete, endpoint, params, nil, client, opts)
  end

  @doc """
  Makes a PUT request to the X API.
  """
  def put(endpoint, params \\ [], client \\ nil, opts \\ []) do
    request(:put, endpoint, params, nil, client, opts)
  end

  # Private functions

  defp request(method, endpoint, params, body, client, opts) do
    client = client || XClient.client()

    with :ok <- Auth.validate_credentials(client),
         :ok <- check_rate_limit(endpoint, client),
         {:ok, response} <- make_request(method, endpoint, params, body, client, opts) do
      update_rate_limit(endpoint, response)
      parse_response(response)
    else
      # make_request returns {:error, {:rate_limited, info}}; check_rate_limit returns {:error, :rate_limited}
      {:error, {:rate_limited, _info}} = error ->
        handle_rate_limit(method, endpoint, params, body, client, opts, error)

      {:error, :rate_limited} = error ->
        handle_rate_limit(method, endpoint, params, body, client, opts, error)

      {:error, _} = error ->
        error
    end
  end

  defp make_request(method, endpoint, params, body, client, opts) do
    base_url = Keyword.get(opts, :base_url, Config.base_url())
    url = build_url(base_url, endpoint)

    headers = build_headers(method, url, params, body, client, opts)

    req_opts = [
      method: method,
      url: url,
      headers: headers
    ]

    req_opts =
      case method do
        :get ->
          Keyword.put(req_opts, :params, params)

        :delete ->
          Keyword.put(req_opts, :params, params)

        _ ->
          if body do
            req_opts
            |> Keyword.put(:body, body)
            |> Keyword.put(:params, params)
          else
            Keyword.put(req_opts, :form, params)
          end
      end

    case Req.request(req_opts) do
      {:ok, %{status: status} = response} when status in 200..299 ->
        {:ok, response}

      {:ok, %{status: 429} = response} ->
        {:error, {:rate_limited, extract_rate_limit_info(response)}}

      {:ok, %{status: status, body: body}} ->
        {:error, %Error{status: status, message: parse_error_message(body)}}

      {:error, error} ->
        {:error, %Error{message: inspect(error)}}
    end
  end

  defp build_url(base_url, endpoint) do
    endpoint = String.trim_leading(endpoint, "/")
    "#{base_url}/#{endpoint}"
  end

  defp build_headers(method, url, params, body, client, opts) do
    content_type = Keyword.get(opts, :content_type)

    auth_params =
      if body && is_binary(body) do
        # For multipart/form-data, don't include body in OAuth signature
        params
      else
        params
      end

    auth_header = Auth.authorization_header(to_string(method) |> String.upcase(), url, auth_params, client)

    headers = [
      {"authorization", auth_header},
      {"accept", "application/json"}
    ]

    if content_type do
      [{"content-type", content_type} | headers]
    else
      headers
    end
  end

  defp parse_response(%{body: body}) when is_map(body) or is_list(body) do
    {:ok, body}
  end

  defp parse_response(%{body: body}) when is_binary(body) do
    case Jason.decode(body) do
      {:ok, decoded} -> {:ok, decoded}
      {:error, _} -> {:ok, body}
    end
  end

  defp parse_response(response) do
    {:ok, response}
  end

  defp parse_error_message(body) when is_map(body) do
    cond do
      Map.has_key?(body, "errors") && is_list(body["errors"]) ->
        body["errors"]
        |> Enum.map(& &1["message"])
        |> Enum.join(", ")

      Map.has_key?(body, "error") ->
        body["error"]

      true ->
        inspect(body)
    end
  end

  defp parse_error_message(body) when is_binary(body) do
    case Jason.decode(body) do
      {:ok, decoded} -> parse_error_message(decoded)
      {:error, _} -> body
    end
  end

  defp parse_error_message(body), do: inspect(body)

  defp check_rate_limit(endpoint, _client) do
    if Config.auto_retry?() do
      case RateLimiter.check_limit(endpoint) do
        :ok -> :ok
        {:error, _} = error -> error
      end
    else
      :ok
    end
  end

  defp update_rate_limit(endpoint, response) do
    rate_limit_info = extract_rate_limit_info(response)

    if rate_limit_info[:remaining] do
      RateLimiter.update_limit(endpoint, rate_limit_info)
    end
  end

  defp extract_rate_limit_info(response) do
    headers = Map.get(response, :headers, %{})

    %{
      limit: get_header_int(headers, "x-rate-limit-limit"),
      remaining: get_header_int(headers, "x-rate-limit-remaining"),
      reset: get_header_int(headers, "x-rate-limit-reset")
    }
  end

  defp get_header_int(headers, key) do
    case List.keyfind(headers, key, 0) do
      {^key, value} -> String.to_integer(value)
      nil -> nil
    end
  rescue
    _ -> nil
  end

  defp handle_rate_limit(method, endpoint, params, body, client, opts, error) do
    retry_count = Keyword.get(opts, :retry_count, 0)
    max_retries = Config.max_retries()

    if Config.auto_retry?() && retry_count < max_retries do
      wait_time = calculate_backoff(retry_count)
      Process.sleep(wait_time)

      opts = Keyword.put(opts, :retry_count, retry_count + 1)
      request(method, endpoint, params, body, client, opts)
    else
      error
    end
  end

  defp calculate_backoff(retry_count) do
    # Exponential backoff: 1s, 2s, 4s, etc.
    :math.pow(2, retry_count) * 1000 |> round()
  end
end
