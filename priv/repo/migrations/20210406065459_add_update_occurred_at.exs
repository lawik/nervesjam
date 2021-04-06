defmodule Nervespub.Repo.Migrations.AddUpdateOccurredAt do
  use Ecto.Migration

  def change do
    alter table(:updates) do
      add :occurred_at, :utc_datetime
    end
  end
end
