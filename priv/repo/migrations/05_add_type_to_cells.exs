defmodule Jeoparty.Repo.Migrations.AddTypeToCells do
  use Ecto.Migration

  def change do
    alter table(:question_cells) do
      add :type, :string, default: "text"
    end
  end
end
