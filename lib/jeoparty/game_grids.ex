defmodule Jeoparty.GameGrids do
  @moduledoc """
  The GameGrids context.
  """

  import Ecto.Query, warn: false
  alias Jeoparty.Repo

  alias Jeoparty.GameGrids.GameGrid

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
end
