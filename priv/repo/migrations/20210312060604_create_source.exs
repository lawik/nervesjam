defmodule Nervespub.Repo.Migrations.CreateSource do
  use Ecto.Migration

  def change do
    create table(:sources) do
      add :name, :text
      add :type, :string
      add :identifier, :string
      add :official, :boolean, default: false, null: false
      add :url, :text

      timestamps()
    end

  end
end
