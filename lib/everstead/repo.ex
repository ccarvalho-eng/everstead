defmodule Everstead.Repo do
  use Ecto.Repo,
    otp_app: :everstead,
    adapter: Ecto.Adapters.Postgres
end
