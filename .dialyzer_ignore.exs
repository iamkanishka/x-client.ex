# .dialyzer_ignore.exs
#
# Selective suppression for known-safe dialyzer warnings.
#
# Format: each entry is a tuple matching the dialyzer warning output.
# Patterns are matched against the string representation of the warning.
#
# IMPORTANT: Keep this file minimal. Every entry here is a potential blind
# spot. Prefer fixing the root cause over adding an ignore entry.
#
# Reference: https://github.com/jeremyjh/dialyxir#filtering-warnings
#
# Example entry shapes:
#   {"lib/x_client/http.ex", :no_return, {:function, :some_fun, 2}}
#   {~r/lib\/x_client\/media\.ex:\d+:pattern_match/, :_}

[
  # OAuther internals — the library's own typespecs are slightly loose on
  # the `params()` return type of `sign/4`, causing occasional
  # underspecs warnings when dialyzer analyses our wrappers against its PLT.
  # This is a known OAuther upstream issue and does not affect runtime behaviour.
  {~r/deps\/oauther/, :_}
]
