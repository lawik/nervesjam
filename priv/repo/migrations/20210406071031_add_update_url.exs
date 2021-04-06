defmodule Nervespub.Repo.Migrations.AddUpdateUrl do
  use Ecto.Migration

  def change do
    alter table(:updates) do
      add :url, :text
    end
  end
end
