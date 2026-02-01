defmodule XClient.Application do
  use Application

  def start(_type, _args) do
    children = [
      XClient.RateLimiter
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: XClient.Supervisor)
  end
end
