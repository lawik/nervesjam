defmodule Nervespub.Repo.Migrations.AddUpdateName do
  use Ecto.Migration

  def change do
    alter table(:updates) do
      add :name, :text
    end
  end
end
