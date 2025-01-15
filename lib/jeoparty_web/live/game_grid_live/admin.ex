defmodule JeopartyWeb.GameGridLive.Admin do
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
     |> assign(:viewed_cell_id, nil)
     |> assign(:page_title, "Admin View - #{game_grid.name}")}
  end

  @impl true
  def handle_event("reveal_cell", %{"id" => cell_id}, socket) do
    cell = Enum.find(socket.assigns.cells, &(&1.id == cell_id))
    PubSub.broadcast(Jeoparty.PubSub, "game_grid:#{socket.assigns.game_grid.id}", {:reveal_cell, cell})
    {:noreply, socket}
  end

  @impl true
  def handle_event("hide_cell", %{"id" => cell_id}, socket) do
    cell = Enum.find(socket.assigns.cells, &(&1.id == cell_id))
    PubSub.broadcast(Jeoparty.PubSub, "game_grid:#{socket.assigns.game_grid.id}", {:hide_cell, cell})
    {:noreply, socket}
  end

  @impl true
  def handle_event("hide_all", _params, socket) do
    Enum.each(socket.assigns.cells, fn cell ->
      PubSub.broadcast(Jeoparty.PubSub, "game_grid:#{socket.assigns.game_grid.id}", {:hide_cell, cell})
    end)
    {:noreply, socket |> assign(:revealed_cells, MapSet.new())}
  end

  @impl true
  def handle_event("view_cell", %{"id" => cell_id}, socket) do
    cell = Enum.find(socket.assigns.cells, &(&1.id == cell_id))

    if socket.assigns.viewed_cell_id == cell_id do
      # If this cell is already being viewed, close it
      PubSub.broadcast(Jeoparty.PubSub, "game_grid:#{socket.assigns.game_grid.id}", {:close_preview, nil})
      {:noreply, socket |> assign(:viewed_cell_id, nil)}
    else
      # Show the new cell
      PubSub.broadcast(Jeoparty.PubSub, "game_grid:#{socket.assigns.game_grid.id}", {:reveal_cell, cell})
      PubSub.broadcast(Jeoparty.PubSub, "game_grid:#{socket.assigns.game_grid.id}", {:preview_cell, cell})
      {:noreply, socket |> assign(:viewed_cell_id, cell_id)}
    end
  end

  @impl true
  def handle_info({:cell_selected, cell}, socket) do
    PubSub.broadcast(Jeoparty.PubSub, "game_grid:#{socket.assigns.game_grid.id}", {:reveal_cell, cell})
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
  def handle_info({:preview_cell, _cell}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info({:close_preview, _}, socket) do
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
