defmodule Jeoparty.Games.Team do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :id, autogenerate: true}
  schema "teams" do
    field :name, :string
    field :score, :integer, default: 0
    belongs_to :game_grid, Jeoparty.GameGrids.GameGrid, type: :binary_id

    timestamps()
  end

  def changeset(team, attrs) do
    team
    |> cast(attrs, [:name, :score, :game_grid_id])
    |> validate_required([:name, :game_grid_id])
    |> validate_number(:score, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:game_grid_id)
  end
end
