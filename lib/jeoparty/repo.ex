defmodule Jeoparty.Repo do
  use Ecto.Repo,
    otp_app: :jeoparty,
    adapter: Ecto.Adapters.Postgres
end
