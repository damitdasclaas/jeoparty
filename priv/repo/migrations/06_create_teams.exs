defmodule Jeoparty.Repo.Migrations.CreateTeams do
  use Ecto.Migration

  def change do
    create table(:teams, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :score, :integer, default: 0
      add :game_grid_id, references(:game_grids, on_delete: :delete_all, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:teams, [:game_grid_id])
  end
end
