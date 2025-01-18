defmodule Jeoparty.Teams.Team do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "teams" do
    field :name, :string
    field :score, :integer, default: 0
    belongs_to :game_grid, Jeoparty.GameGrids.GameGrid

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(team, attrs) do
    team
    |> cast(attrs, [:name, :score, :game_grid_id])
    |> validate_required([:name, :game_grid_id])
    |> validate_number(:score, greater_than_or_equal_to: 0)
  end
end
