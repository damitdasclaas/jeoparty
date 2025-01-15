defmodule Jeoparty.GameGridsTest do
  use Jeoparty.DataCase

  alias Jeoparty.GameGrids

  describe "game_grids" do
    alias Jeoparty.GameGrids.GameGrid

    import Jeoparty.GameGridsFixtures

    @invalid_attrs %{name: nil, columns: nil, rows: nil}

    test "list_game_grids/0 returns all game_grids" do
      game_grid = game_grid_fixture()
      assert GameGrids.list_game_grids() == [game_grid]
    end

    test "get_game_grid!/1 returns the game_grid with given id" do
      game_grid = game_grid_fixture()
      assert GameGrids.get_game_grid!(game_grid.id) == game_grid
    end

    test "create_game_grid/1 with valid data creates a game_grid" do
      valid_attrs = %{name: "some name", columns: 42, rows: 42}

      assert {:ok, %GameGrid{} = game_grid} = GameGrids.create_game_grid(valid_attrs)
      assert game_grid.name == "some name"
      assert game_grid.columns == 42
      assert game_grid.rows == 42
    end

    test "create_game_grid/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = GameGrids.create_game_grid(@invalid_attrs)
    end

    test "update_game_grid/2 with valid data updates the game_grid" do
      game_grid = game_grid_fixture()
      update_attrs = %{name: "some updated name", columns: 43, rows: 43}

      assert {:ok, %GameGrid{} = game_grid} = GameGrids.update_game_grid(game_grid, update_attrs)
      assert game_grid.name == "some updated name"
      assert game_grid.columns == 43
      assert game_grid.rows == 43
    end

    test "update_game_grid/2 with invalid data returns error changeset" do
      game_grid = game_grid_fixture()
      assert {:error, %Ecto.Changeset{}} = GameGrids.update_game_grid(game_grid, @invalid_attrs)
      assert game_grid == GameGrids.get_game_grid!(game_grid.id)
    end

    test "delete_game_grid/1 deletes the game_grid" do
      game_grid = game_grid_fixture()
      assert {:ok, %GameGrid{}} = GameGrids.delete_game_grid(game_grid)
      assert_raise Ecto.NoResultsError, fn -> GameGrids.get_game_grid!(game_grid.id) end
    end

    test "change_game_grid/1 returns a game_grid changeset" do
      game_grid = game_grid_fixture()
      assert %Ecto.Changeset{} = GameGrids.change_game_grid(game_grid)
    end
  end
end
