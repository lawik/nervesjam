defmodule Nervespub.Sourcing.Update do
  use Ecto.Schema
  import Ecto.Changeset
  alias Nervespub.Sourcing.Source

  schema "updates" do
    field :text, :string
    field :type, :string
    field :occurred_at, :datetime

    belongs_to(:source, Source)

    timestamps()
  end

  @doc false
  def changeset(update, attrs) do
    update
    |> cast(attrs, [:text, :type])
    |> validate_required([:text, :type])
  end
end
