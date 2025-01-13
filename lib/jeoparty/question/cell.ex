defmodule Jeoparty.Question.Cell do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "question_cells" do
    field :data, :map
    field :column, :integer
    field :row, :integer
    field :game_grid_id, :binary_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(cell, attrs) do
    cell
    |> cast(attrs, [:row, :column, :data])
    |> validate_required([:row, :column])
  end
end
