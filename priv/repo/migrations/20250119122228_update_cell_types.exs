defmodule Jeoparty.Repo.Migrations.UpdateCellTypes do
  use Ecto.Migration

  def change do
    drop_if_exists constraint(:question_cells, :type_inclusion)
    create constraint(:question_cells, :type_inclusion, check: "type in ('text', 'picture', 'video', 'audio')")
  end
end
