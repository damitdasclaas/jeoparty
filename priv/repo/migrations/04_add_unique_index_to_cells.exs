defmodule Jeoparty.Repo.Migrations.AddUniqueIndexToCells do
  use Ecto.Migration

  def change do
    create unique_index(:question_cells, [:game_grid_id, :row, :column],
      name: :question_cells_position_index)
  end
end
