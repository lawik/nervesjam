defmodule Nervespub.Repo do
  use Ecto.Repo,
    otp_app: :nervespub,
    adapter: Ecto.Adapters.Exqlite
end
