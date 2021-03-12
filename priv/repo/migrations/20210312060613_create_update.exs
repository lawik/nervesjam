defmodule Nervespub.Repo.Migrations.CreateUpdate do
  use Ecto.Migration

  def change do
    create table(:updates) do
      add :text, :text
      add :type, :string
      add :source_id, references(:sources)

      timestamps()
    end

  end
end
