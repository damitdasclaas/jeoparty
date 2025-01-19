defmodule JeopartyWeb.GameGridLive.Index do
  use JeopartyWeb, :live_view

  alias Jeoparty.GameGrids
  alias Jeoparty.GameGrids.GameGrid

  @impl true
  def mount(_params, _session, socket) do
    games = GameGrids.list_game_grids()

    {:ok,
     socket
     |> assign(:current_user, socket.assigns.current_user)
     |> assign(:games, games)
     |> assign(:has_games, length(games) > 0)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Game grid")
    |> assign(:game_grid, GameGrids.get_game_grid!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Game grid")
    |> assign(:game_grid, %GameGrid{})
  end

  defp apply_action(socket, :index, _params) do
    games = GameGrids.list_game_grids()

    socket
    |> assign(:page_title, "Listing Game grids")
    |> assign(:game_grid, nil)
    |> assign(:games, games)
    |> assign(:has_games, length(games) > 0)
  end

  @impl true
  def handle_info({JeopartyWeb.GameGridLive.FormComponent, {:saved, _game_grid}}, socket) do
    games = GameGrids.list_game_grids()

    {:noreply,
     socket
     |> assign(:games, games)
     |> assign(:has_games, length(games) > 0)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    game_grid = GameGrids.get_game_grid!(id)
    {:ok, _} = GameGrids.delete_game_grid(game_grid)

    games = GameGrids.list_game_grids()

    {:noreply,
     socket
     |> assign(:games, games)
     |> assign(:has_games, length(games) > 0)}
  end

  @impl true
  def handle_event("duplicate", %{"id" => id}, socket) do
    original_grid = GameGrids.get_game_grid!(id)
    original_cells = GameGrids.get_cells_for_grid(id)

    # Create a copy of the game grid with a new name
    attrs = Map.from_struct(original_grid)
    |> Map.drop([:__meta__, :id, :inserted_at, :updated_at, :cells, :teams, :user])
    |> Map.put(:name, "#{original_grid.name} (Copy)")

    case GameGrids.create_game_grid(attrs) do
      {:ok, new_grid} ->
        # Copy all cells
        Enum.each(original_cells, fn cell ->
          cell_attrs = Map.from_struct(cell)
          |> Map.drop([:__meta__, :id, :inserted_at, :updated_at, :game_grid])
          |> Map.put(:game_grid_id, new_grid.id)

          GameGrids.create_cell(cell_attrs)
        end)

        games = GameGrids.list_game_grids()

        {:noreply,
         socket
         |> assign(:games, games)
         |> assign(:has_games, length(games) > 0)}

      {:error, _changeset} ->
        {:noreply, socket}
    end
  end
end
