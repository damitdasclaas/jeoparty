defmodule Jeoparty.Repo.Migrations.AddSelectedAnswersToGameGrids do
  use Ecto.Migration

  def change do
    alter table(:game_grids) do
      add :selected_answers, :map, default: %{}, null: false
    end
  end
end
