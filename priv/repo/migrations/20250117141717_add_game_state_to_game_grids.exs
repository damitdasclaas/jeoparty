defmodule Jeoparty.Repo.Migrations.AddGameStateToGameGrids do
  use Ecto.Migration

  def change do
    alter table(:game_grids) do
      # Store revealed cell IDs as an array of strings (binary_ids)
      add :revealed_cell_ids, {:array, :string}, default: [], null: false
      # Store the currently viewed cell ID
      add :viewed_cell_id, :string, null: true
    end
  end
end
