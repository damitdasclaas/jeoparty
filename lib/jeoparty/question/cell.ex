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
    field :is_category, :boolean, default: false

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(cell, attrs) do
    cell
    |> cast(attrs, [:row, :column, :data, :game_grid_id, :is_category])
    |> validate_required([:row, :column, :game_grid_id])
    |> maybe_set_category()
    |> unique_constraint([:game_grid_id, :row, :column],
      name: :question_cells_position_index,
      message: "A cell already exists at this position")
  end

  defp maybe_set_category(changeset) do
    case get_field(changeset, :row) do
      1 -> put_change(changeset, :is_category, true)
      _ -> changeset
    end
  end
end
