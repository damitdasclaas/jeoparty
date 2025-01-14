defmodule Jeoparty.GameGrids.GameGrid do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "game_grids" do
    field :name, :string
    field :columns, :integer
    field :rows, :integer

    belongs_to :user, Jeoparty.Accounts.User, foreign_key: :created_by

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(game_grid, attrs) do
    game_grid
    |> cast(attrs, [:name, :columns, :rows, :created_by])
    |> validate_required([:name, :columns, :rows, :created_by])
  end
end
