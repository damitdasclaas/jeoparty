defmodule Jeoparty.GameGridsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Jeoparty.GameGrids` context.
  """

  @doc """
  Generate a game_grid.
  """
  def game_grid_fixture(attrs \\ %{}) do
    {:ok, game_grid} =
      attrs
      |> Enum.into(%{
        columns: 42,
        name: "some name",
        rows: 42
      })
      |> Jeoparty.GameGrids.create_game_grid()

    game_grid
  end
end
