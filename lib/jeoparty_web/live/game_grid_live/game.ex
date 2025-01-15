defmodule JeopartyWeb.GameGridLive.Game do
  use JeopartyWeb, :live_view
  alias Jeoparty.GameGrids
  alias Phoenix.PubSub

  @impl true
  def mount(%{"id" => grid_id}, _session, socket) do
    if connected?(socket) do
      PubSub.subscribe(Jeoparty.PubSub, "game_grid:#{grid_id}")
    end

    game_grid = GameGrids.get_game_grid!(grid_id)
    cells = GameGrids.get_cells_for_grid(grid_id)

    {:ok,
     socket
     |> assign(:game_grid, game_grid)
     |> assign(:cells, cells)
     |> assign(:revealed_cells, MapSet.new())
     |> assign(:selected_cell, nil)
     |> assign(:show_modal, false)
     |> assign(:page_title, "Game View - #{game_grid.name}")}
  end

  @impl true
  def handle_event("select_cell", %{"id" => cell_id}, socket) do
    cell = Enum.find(socket.assigns.cells, &(&1.id == cell_id))

    if not cell.is_category do
      PubSub.broadcast(Jeoparty.PubSub, "game_grid:#{socket.assigns.game_grid.id}", {:cell_selected, cell})
      PubSub.broadcast(Jeoparty.PubSub, "game_grid:#{socket.assigns.game_grid.id}", {:view_toggled, cell})
      {:noreply, socket |> assign(:selected_cell, cell) |> assign(:show_modal, true)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("close_modal", _, socket) do
    if socket.assigns.selected_cell do
      PubSub.broadcast(Jeoparty.PubSub, "game_grid:#{socket.assigns.game_grid.id}", {:view_toggled, nil})
      PubSub.broadcast(Jeoparty.PubSub, "game_grid:#{socket.assigns.game_grid.id}", {:reveal_cell, socket.assigns.selected_cell})
    end
    {:noreply, socket |> assign(:show_modal, false) |> assign(:selected_cell, nil)}
  end

  @impl true
  def handle_info({:cell_selected, _cell}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info({:reveal_cell, cell}, socket) do
    {:noreply,
     socket
     |> assign(:revealed_cells, MapSet.put(socket.assigns.revealed_cells, cell.id))}
  end

  @impl true
  def handle_info({:hide_cell, cell}, socket) do
    {:noreply,
     socket
     |> assign(:revealed_cells, MapSet.delete(socket.assigns.revealed_cells, cell.id))}
  end

  @impl true
  def handle_info({:preview_cell, cell}, socket) do
    {:noreply, socket |> assign(:selected_cell, cell) |> assign(:show_modal, true)}
  end

  @impl true
  def handle_info({:close_preview, _}, socket) do
    {:noreply, socket |> assign(:show_modal, false) |> assign(:selected_cell, nil)}
  end

  @impl true
  def handle_info({:view_toggled, _cell}, socket) do
    {:noreply, socket}
  end

  defp get_cell(cells, row, col) do
    row = if is_binary(row), do: String.to_integer(row), else: row
    col = if is_binary(col), do: String.to_integer(col), else: col

    Enum.find(cells, fn cell ->
      cell.row == row && cell.column == col
    end)
  end
end
