defmodule JeopartyWeb.GameGridLive.Game do
  use JeopartyWeb, :live_view
  alias Jeoparty.GameGrids
  alias Jeoparty.Teams
  alias Phoenix.PubSub

  @impl true
  def mount(%{"id" => grid_id}, _session, socket) do
    if connected?(socket) do
      PubSub.subscribe(Jeoparty.PubSub, "game_grid:#{grid_id}")
    end

    game_grid = GameGrids.get_game_grid!(grid_id)
    cells = GameGrids.get_cells_for_grid(grid_id)
    teams = Teams.list_teams_for_game(grid_id)

    {:ok,
     socket
     |> assign(:game_grid, game_grid)
     |> assign(:cells, cells)
     |> assign(:teams, teams)
     |> assign(:revealed_cells, MapSet.new(game_grid.revealed_cell_ids || []))
     |> assign(:show_modal, false)
     |> assign(:selected_cell, nil)
     |> assign(:page_title, "Game View - #{game_grid.name}")}
  end

  @impl true
  def handle_event("select_cell", %{"id" => cell_id}, socket) do
    cell = Enum.find(socket.assigns.cells, &(&1.id == cell_id))

    if cell && !cell.is_category do
      {:ok, game_grid} = GameGrids.reveal_cell(socket.assigns.game_grid, cell_id)
      PubSub.broadcast(Jeoparty.PubSub, "game_grid:#{socket.assigns.game_grid.id}", {:cell_selected, cell})

      {:noreply,
       socket
       |> assign(:game_grid, game_grid)
       |> assign(:revealed_cells, MapSet.new(game_grid.revealed_cell_ids))
       |> assign(:show_modal, true)
       |> assign(:selected_cell, cell)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("close_modal", _, socket) do
    if socket.assigns.selected_cell do
      PubSub.broadcast(Jeoparty.PubSub, "game_grid:#{socket.assigns.game_grid.id}", {:view_toggled, nil})
      PubSub.broadcast(Jeoparty.PubSub, "game_grid:#{socket.assigns.game_grid.id}", {:close_preview, nil})
    end

    {:noreply,
     socket
     |> assign(:show_modal, false)
     |> assign(:selected_cell, nil)}
  end

  @impl true
  def handle_info({:cell_selected, cell}, socket) do
    {:ok, game_grid} = GameGrids.reveal_cell(socket.assigns.game_grid, cell.id)

    {:noreply,
     socket
     |> assign(:game_grid, game_grid)
     |> assign(:revealed_cells, MapSet.new(game_grid.revealed_cell_ids))
     |> assign(:show_modal, true)
     |> assign(:selected_cell, cell)}
  end

  @impl true
  def handle_info({:reveal_cell, cell}, socket) do
    {:ok, game_grid} = GameGrids.reveal_cell(socket.assigns.game_grid, cell.id)

    {:noreply,
     socket
     |> assign(:game_grid, game_grid)
     |> assign(:revealed_cells, MapSet.new(game_grid.revealed_cell_ids))}
  end

  @impl true
  def handle_info({:hide_cell, cell}, socket) do
    {:ok, game_grid} = GameGrids.hide_cell(socket.assigns.game_grid, cell.id)

    {:noreply,
     socket
     |> assign(:game_grid, game_grid)
     |> assign(:revealed_cells, MapSet.new(game_grid.revealed_cell_ids))}
  end

  @impl true
  def handle_info({:preview_cell, cell}, socket) do
    {:noreply,
     socket
     |> assign(:show_modal, true)
     |> assign(:selected_cell, cell)}
  end

  @impl true
  def handle_info({:close_preview, _}, socket) do
    {:noreply,
     socket
     |> assign(:show_modal, false)
     |> assign(:selected_cell, nil)}
  end

  @impl true
  def handle_info(:reset_game, socket) do
    {:noreply,
     socket
     |> assign(:revealed_cells, MapSet.new())
     |> assign(:show_modal, false)
     |> assign(:selected_cell, nil)}
  end

  @impl true
  def handle_info({:standings_toggled, show_standings}, socket) do
    {:ok, game_grid} = GameGrids.update_game_grid(socket.assigns.game_grid, %{show_standings: show_standings})
    teams = Teams.list_teams_for_game(socket.assigns.game_grid.id)

    {:noreply,
     socket
     |> assign(:game_grid, game_grid)
     |> assign(:teams, teams)}
  end

  defp get_cell(cells, row, col) do
    row = if is_binary(row), do: String.to_integer(row), else: row
    col = if is_binary(col), do: String.to_integer(col), else: col

    Enum.find(cells, fn cell ->
      cell.row == row && cell.column == col
    end)
  end
end
