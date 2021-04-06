defmodule Nervespub.Sourcing.Update do
  use Ecto.Schema
  import Ecto.Changeset
  alias Nervespub.Sourcing.Source

  schema "updates" do
    field :text, :string
    field :type, :string
    field :occurred_at, :utc_datetime
    field :reference, :string
    field :url, :string

    belongs_to(:source, Source)

    timestamps()
  end

  @doc false
  @keys [
    :text,
    :type,
    :occurred_at,
    :reference,
    :url,
    :source_id
  ]
  def changeset(update, attrs) do
    update
    |> cast(attrs, @keys)
    |> validate_required(@keys)
  end
end
