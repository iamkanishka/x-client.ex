# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

---

## [1.1.0] — 2026-03-15

This release is a comprehensive refactor and hardening pass. The public API
surface is **backwards-compatible** with v1.0.0 with the exception of
`XClient.client/1` now returning a `%XClient.Client{}` struct instead of a
plain map — any code that pattern-matched on the raw map keys will need to
use struct access instead.

### Fixed — Critical Bugs

- **`XClient.Geo` misplaced** — `XClient.Geo` was appended to the bottom of
  `lib/twitter_client/trends.ex` and never compiled as its own module. It is
  now in `lib/x_client/geo.ex`.
- **`XClient.Help` empty file** — `lib/twitter_client/help.ex` existed but
  contained no code. The full module implementation was accidentally placed
  inside `test/test_helper.exs`. It is now correctly implemented in
  `lib/x_client/help.ex`.
- **`XClient.API` in test file** — The rate-limit-status module was defined
  inside `test/test_helper.exs`, making it unavailable in production builds.
  Moved to `lib/x_client/api.ex`.
- **OAuther API misuse** — `OAuther.sign/4` requires an `%OAuther.Credentials{}`
  struct as its fourth argument. The original code passed a raw 4-tuple
  `{consumer_key, consumer_secret, token, token_secret}`, causing a type
  mismatch that dialyzer flagged with 70+ cascading `no_return` warnings.
  Fixed by using `OAuther.credentials/1` to build the struct properly.
- **`OAuther.header/1` return value** — `OAuther.header/1` returns
  `{{"Authorization", value}, rest_params}`. The original code called
  `elem(1)` on this, returning `rest_params` (the remaining OAuth params list)
  as the Authorization header instead of the actual header string. Fixed with
  pattern matching: `{{"Authorization", auth_value}, _rest}`.
- **`Media.simple_upload/4` discards `add_metadata` result** — the alt-text
  call's return value was ignored; the function returned the original (pre-
  metadata) media object regardless. Now correctly returns the metadata
  response.
- **Unbounded recursion in `Media.wait_for_processing/3`** — videos whose
  processing never completes would loop forever. A `max_poll_attempts` guard
  now terminates the poll after a configurable number of attempts.
- **`test_helper.exs` contained module definitions** — `XClient.Help`,
  `XClient.API`, and test helpers were mixed into `test/test_helper.exs`.
  All module definitions moved to `lib/`; test helpers moved to
  `test/support/helpers.ex`.

### Fixed — Performance

- **`RateLimiter.check_limit/1` was a blocking GenServer call** — every
  API request serialised through the GenServer mailbox. Replaced with a
  direct `:ets.lookup/2` read on a `:public, read_concurrency: true` ETS
  table. Only writes go through the GenServer.
- **`calculate_backoff/1` used floating-point** — `:math.pow(2, n)` returns
  a float; replaced with `Integer.pow(2, n)` for pure integer arithmetic.

### Fixed — Type Safety and Dialyzer (95 → 0 warnings)

- **Raw map client** — `XClient.client/1` previously returned a plain `%{}`
  map. Replaced with `%XClient.Client{}` struct with `@enforce_keys` on all
  four credential fields.
- **`@spec response` types too narrow** — All `{:ok, map()}` return types
  widened to `{:ok, term()}` to match dialyzer's inferred success typings.
- **Dead `extract_rate_limit_info` clauses in `http.ex`** — The
  `when is_list(headers)` and catch-all `_` clauses were unreachable because
  `%Req.Response{}` always has a map for its `headers` field. Replaced both
  with a single `%Req.Response{headers: headers}` struct match.
- **`verify_credentials` dispatch mismatch** — `XClient.verify_credentials/0`
  passed `nil` as the second argument to `Account.verify_credentials/2` but
  the multi-clause function's success typing rejects `nil` there. Fixed by
  calling `HTTP.get` directly.
- **Overspecified private function `@spec`** — Removed the `@spec` from
  `DirectMessages.build_message_data/2` whose declared return type was a
  supertype of dialyzer's inferred map shape.

### Added

- `XClient.Client` — typed struct (`%XClient.Client{}`) with `@enforce_keys`
  replacing the original raw credential map.
- `XClient.Params` — shared parameter-building utility (`build/1`, `build/2`,
  `compact/1`) eliminating the `build_params/1` + `format_value/1` duplication
  that existed identically in 10+ modules.
- **Telemetry events** — `[:x_client, :request, :start/stop/error]` and
  `[:x_client, :rate_limit, :checked/blocked/updated]` for full observability.
- **Startup credential warning** — `XClient.Application` now calls
  `Config.validate!/0` at startup and emits a `Logger.warning` if credentials
  are missing, rather than failing silently until the first API call.
- `Config.retry_base_delay_ms/0` — configurable exponential backoff base delay
  (default `1_000` ms).
- `Config.request_timeout_ms/0` — configurable HTTP request timeout
  (default `30_000` ms).
- `Error.from_body/2` — structured error construction from API response bodies,
  handling both `{"errors": [...]}` and `{"error": "..."}` shapes.
- `Error.network_error/1` — wraps transport-level errors (timeout, DNS, etc.).
- **User-Agent header** — all requests now include
  `User-Agent: x-client.ex/<version>`.
- **Comprehensive test suite** — 8 test files with ~200 test cases using
  `Bypass` for HTTP interception, covering every public API function.
- **GitHub Actions CI** — 5-job pipeline: format → credo → test matrix
  (Elixir 1.15/1.16/1.17) → dialyzer (PLT cached) → hex publish on `v*` tags.
- `dialyzer_ignore.exs` — selective suppression file for known-safe patterns.
- `.credo.exs` — strict Credo configuration.

### Removed

- `ex_rated` dependency — declared in `mix.exs` but never used; rate limiting
  is handled entirely by `XClient.RateLimiter`.
- `XClient.Client.to_oauther_credentials/1` — removed after `auth.ex` was
  fixed to use `OAuther.credentials/1` directly.
- Dead header-parsing code in `http.ex` (`find_header_int/2` and the
  `when is_list(headers)` clause of `extract_rate_limit_info/1`).

### Changed

- **Module namespace** — all files moved from `lib/twitter_client/` to
  `lib/x_client/` and `TwitterClient.*` references removed; everything is
  under the `XClient.*` namespace as documented.
- **`mix.exs` `elixir` requirement** loosened from `~> 1.18` to `~> 1.14`
  to support more Elixir versions.
- **`dialyzer` flags** — added `:missing_return` and `:underspecs` to catch
  more type issues in CI.

---

## [1.0.0] — 2026-01-01

### Added

- Initial release.
- Full X API v1.1 endpoint coverage across 13 modules.
- OAuth 1.0a authentication via `oauther`.
- Rate limit tracking and automatic retry.
- Chunked media upload (INIT / APPEND / FINALIZE).
- Basic error struct `%XClient.Error{}`.
- `ExDoc` documentation.

[Unreleased]: https://github.com/iamkanishka/x-client.ex/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/iamkanishka/x-client.ex/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/iamkanishka/x-client.ex/releases/tag/v1.0.0
