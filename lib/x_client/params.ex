defmodule XClient.Params do
  @moduledoc """
  Shared parameter-building utilities used by all API modules.

  Eliminates the duplicated `build_params/1` + `format_value/1` pattern
  that previously existed in every module.
  """

  @doc """
  Converts a keyword list or map of options into a flat map of string-safe values
  suitable for use as HTTP query params or form body.

  - Lists are joined with commas: `[1, 2, 3]` → `"1,2,3"`
  - Booleans become strings: `true` → `"true"`
  - `nil` values are **dropped**
  - All other values are passed through as-is (Req handles to_string coercion)

  ## Example

      iex> XClient.Params.build(screen_name: "elixirlang", count: 50, trim_user: true)
      %{screen_name: "elixirlang", count: 50, trim_user: "true"}
  """
  @spec build(keyword() | map()) :: map()
  def build(opts) when is_list(opts) do
    opts
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new(fn {k, v} -> {k, format(v)} end)
  end

  def build(opts) when is_map(opts) do
    opts
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new(fn {k, v} -> {k, format(v)} end)
  end

  @doc """
  Merges extra key-value pairs into an opts keyword list, then calls `build/1`.

  Convenient for endpoints that always require specific params:

      Params.build(opts, id: tweet_id)
  """
  @spec build(keyword(), keyword()) :: map()
  def build(opts, extra) when is_list(opts) and is_list(extra) do
    build(Keyword.merge(opts, extra))
  end

  # ── Private ──────────────────────────────────────────────────────────────────

  @spec format(term()) :: term()
  defp format(value) when is_list(value), do: Enum.join(value, ",")
  defp format(true), do: "true"
  defp format(false), do: "false"
  defp format(value), do: value
end
