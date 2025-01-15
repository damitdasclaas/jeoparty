defmodule Jeoparty.Repo.Migrations.CreateQuestionCells do
  use Ecto.Migration

  def change do
    create table(:question_cells, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :data, :map
      add :column, :integer
      add :row, :integer
      add :game_grid_id, references(:game_grids, on_delete: :delete_all, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:question_cells, [:game_grid_id])
  end
end
