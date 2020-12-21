defmodule TwoZeroFourEight.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias TwoZeroFourEight.GamesRegistry

  @runtime_env Application.get_env(:two_zero_four_eight, :runtime_env)

  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      TwoZeroFourEightWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: TwoZeroFourEight.PubSub},
      # Start the Endpoint (http/https)
      TwoZeroFourEightWeb.Endpoint,
      Supervisor.Spec.worker(GamesRegistry, [])
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TwoZeroFourEight.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    TwoZeroFourEightWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
