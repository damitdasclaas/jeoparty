defmodule Jeoparty.Repo.Migrations.AddShowStandingsToGameGrids do
  use Ecto.Migration

  def change do
    alter table(:game_grids) do
      add :show_standings, :boolean, default: false
    end
  end
end
