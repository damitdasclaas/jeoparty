defmodule Jeoparty.GameGrids do
  @moduledoc """
  The GameGrids context.
  """

  import Ecto.Query, warn: false
  alias Jeoparty.Repo

  alias Jeoparty.GameGrids.GameGrid
  alias Jeoparty.Question.Cell

  @doc """
  Returns the list of game_grids.

  ## Examples

      iex> list_game_grids()
      [%GameGrid{}, ...]

  """
  def list_game_grids do
    Repo.all(GameGrid)
  end

  @doc """
  Gets a single game_grid.

  Raises `Ecto.NoResultsError` if the Game grid does not exist.

  ## Examples

      iex> get_game_grid!(123)
      %GameGrid{}

      iex> get_game_grid!(456)
      ** (Ecto.NoResultsError)

  """
  def get_game_grid!(id), do: Repo.get!(GameGrid, id)

  @doc """
  Creates a game_grid.

  ## Examples

      iex> create_game_grid(%{field: value})
      {:ok, %GameGrid{}}

      iex> create_game_grid(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_game_grid(attrs \\ %{}) do
    %GameGrid{}
    |> GameGrid.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a game_grid.

  ## Examples

      iex> update_game_grid(game_grid, %{field: new_value})
      {:ok, %GameGrid{}}

      iex> update_game_grid(game_grid, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_game_grid(%GameGrid{} = game_grid, attrs) do
    game_grid
    |> GameGrid.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a game_grid.

  ## Examples

      iex> delete_game_grid(game_grid)
      {:ok, %GameGrid{}}

      iex> delete_game_grid(game_grid)
      {:error, %Ecto.Changeset{}}

  """
  def delete_game_grid(%GameGrid{} = game_grid) do
    Repo.delete(game_grid)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking game_grid changes.

  ## Examples

      iex> change_game_grid(game_grid)
      %Ecto.Changeset{data: %GameGrid{}}

  """
  def change_game_grid(%GameGrid{} = game_grid, attrs \\ %{}) do
    GameGrid.changeset(game_grid, attrs)
  end

  def get_cells_for_grid(grid_id) do
    require Logger
    #Logger.info("Fetching cells for grid: #{grid_id}")

    query = from c in Cell,
      where: c.game_grid_id == ^grid_id

    cells = Repo.all(query)
    #Logger.info("Found cells: #{inspect(cells)}")

    cells
  end

  def delete_cell(%Cell{} = cell) do
    Repo.delete(cell)
  end

  def update_cell(%Cell{} = cell, attrs) do
    cell
    |> Cell.changeset(attrs)
    |> Repo.update()
  end

  def create_cell(attrs \\ %{}) do
    %Cell{}
    |> Cell.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Reveals a cell in the game grid.
  """
  def reveal_cell(%GameGrid{} = game_grid, cell_id) do
    new_revealed_cells = [cell_id | (game_grid.revealed_cell_ids || [])] |> Enum.uniq()
    update_game_grid(game_grid, %{revealed_cell_ids: new_revealed_cells})
  end

  @doc """
  Hides a cell in the game grid.
  """
  def hide_cell(%GameGrid{} = game_grid, cell_id) do
    new_revealed_cells = (game_grid.revealed_cell_ids || []) |> Enum.reject(&(&1 == cell_id))
    update_game_grid(game_grid, %{revealed_cell_ids: new_revealed_cells})
  end

  @doc """
  Sets the currently viewed cell.
  """
  def set_viewed_cell(%GameGrid{} = game_grid, cell_id) do
    game_grid
    |> GameGrid.changeset(%{viewed_cell_id: cell_id})
    |> Repo.update()
  end

  @doc """
  Hides all cells in the game grid.
  """
  def hide_all_cells(%GameGrid{} = game_grid) do
    update_game_grid(game_grid, %{revealed_cell_ids: [], viewed_cell_id: nil})
  end

  def toggle_standings(%GameGrid{} = game_grid) do
    game_grid
    |> GameGrid.changeset(%{show_standings: !game_grid.show_standings})
    |> Repo.update()
  end

  def show_standings(%GameGrid{} = game_grid) do
    game_grid
    |> GameGrid.changeset(%{show_standings: true})
    |> Repo.update()
  end

  def hide_standings(%GameGrid{} = game_grid) do
    game_grid
    |> GameGrid.changeset(%{show_standings: false})
    |> Repo.update()
  end
end
