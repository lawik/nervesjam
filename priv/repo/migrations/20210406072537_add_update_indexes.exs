defmodule Nervespub.Repo.Migrations.AddUpdateIndexes do
  use Ecto.Migration

  def change do
    create index(:updates, [:reference])
    create index(:updates, [:source_id])
  end
end
