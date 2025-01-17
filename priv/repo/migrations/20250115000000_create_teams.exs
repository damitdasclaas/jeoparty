defmodule Jeoparty.Repo.Migrations.CreateTeams do
  use Ecto.Migration

  def change do
    create table(:teams) do
      add :name, :string, null: false
      add :score, :integer, null: false, default: 0
      add :game_grid_id, references(:game_grids, type: :uuid, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:teams, [:game_grid_id])
  end
end
