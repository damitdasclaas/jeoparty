defmodule Jeoparty.Repo.Migrations.AddIsCategoryToCells do
  use Ecto.Migration

  def change do
    alter table(:question_cells) do
      add :is_category, :boolean, default: false
    end
  end
end
