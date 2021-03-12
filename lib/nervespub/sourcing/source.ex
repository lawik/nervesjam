defmodule Nervespub.Sourcing.Source do
  use Ecto.Schema
  import Ecto.Changeset

  schema "sources" do
    field :identifier, :string
    field :name, :string
    field :official, :boolean, default: false
    field :type, :string
    field :url, :string

    timestamps()
  end

  @doc false
  def changeset(source, attrs) do
    source
    |> cast(attrs, [:name, :type, :identifier, :official, :url])
    |> validate_required([:name, :type, :identifier, :official, :url])
  end
end
