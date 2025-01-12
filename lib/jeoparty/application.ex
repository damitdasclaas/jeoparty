defmodule Jeoparty.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      JeopartyWeb.Telemetry,
      Jeoparty.Repo,
      {DNSCluster, query: Application.get_env(:jeoparty, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Jeoparty.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Jeoparty.Finch},
      # Start a worker by calling: Jeoparty.Worker.start_link(arg)
      # {Jeoparty.Worker, arg},
      # Start to serve requests, typically the last entry
      JeopartyWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Jeoparty.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    JeopartyWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
