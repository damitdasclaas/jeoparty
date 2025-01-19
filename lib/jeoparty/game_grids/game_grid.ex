defmodule Jeoparty.GameGrids.GameGrid do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "game_grids" do
    field :name, :string
    field :columns, :integer, default: 4
    field :rows, :integer, default: 3
    field :revealed_cell_ids, {:array, :string}, default: []
    field :viewed_cell_id, :string
    field :show_standings, :boolean, default: false
    field :selected_answers, :map, default: %{}

    belongs_to :user, Jeoparty.Accounts.User, foreign_key: :created_by
    has_many :cells, Jeoparty.Question.Cell, on_delete: :delete_all
    has_many :teams, Jeoparty.Teams.Team, on_delete: :delete_all

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(game_grid, attrs) do
    game_grid
    |> cast(attrs, [:name, :columns, :rows, :created_by, :revealed_cell_ids, :viewed_cell_id, :show_standings, :selected_answers])
    |> validate_required([:name, :columns, :rows, :created_by])
  end
end
