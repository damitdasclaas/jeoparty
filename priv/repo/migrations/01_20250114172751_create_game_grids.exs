defmodule Jeoparty.Repo.Migrations.CreateGameGrids do
  use Ecto.Migration

  def change do
    create table(:game_grids, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :columns, :integer
      add :rows, :integer
      add :created_by, references(:users, on_delete: :nothing, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:game_grids, [:created_by])
  end
end
