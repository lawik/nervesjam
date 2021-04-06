defmodule Nervespub.Repo.Migrations.AddUpdateReference do
  use Ecto.Migration

  def change do
    alter table(:updates) do
      add :reference, :text
    end
  end
end
