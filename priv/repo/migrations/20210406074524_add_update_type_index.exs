defmodule Nervespub.Repo.Migrations.AddUpdateTypeIndex do
  use Ecto.Migration

  def change do
    create index(:updates, [:type])
  end
end
