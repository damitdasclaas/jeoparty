defmodule Jeoparty.Game.Grid do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "game_grids" do
    field :name, :string
    field :columns, :integer
    field :rows, :integer

    has_many :question_cells, Jeoparty.Question.Cell, foreign_key: :game_grid_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(grid, attrs) do
    grid
    |> cast(attrs, [:name, :columns, :rows])
    |> validate_required([:name, :columns, :rows])
  end
end
