defmodule JeopartyWeb.GameGridLive.Show do
  use JeopartyWeb, :live_view

  alias Jeoparty.GameGrids
  alias Jeoparty.Question.Cell

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:current_user, socket.assigns.current_user)
      |> assign(:show_cell_modal, false)
      |> assign(:selected_row, nil)
      |> assign(:selected_column, nil)
      |> assign(:cells, [])
      |> assign(:editing_cell, nil)

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    game_grid = GameGrids.get_game_grid!(id)
    cells = GameGrids.get_cells_for_grid(id)

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:game_grid, game_grid)
     |> assign(:cells, cells)}
  end

  @impl true
  def handle_event("open_cell_modal", %{"row" => row, "col" => col}, socket) do
    row = String.to_integer(row)
    points = get_points(row)

    {:noreply,
     socket
     |> assign(:show_cell_modal, true)
     |> assign(:selected_row, row)
     |> assign(:selected_column, String.to_integer(col))
     |> assign(:points, points)
     |> assign(:editing_cell, nil)}
  end

  @impl true
  def handle_info({JeopartyWeb.GameGridLive.FormComponent, {:saved, game_grid}}, socket) do
    {:noreply,
     socket
     |> assign(:game_grid, game_grid)
     |> assign(:cells, GameGrids.get_cells_for_grid(game_grid.id))
     |> put_flash(:info, "Game grid updated successfully")}
  end

  @impl true
  def handle_info({:cell_created}, socket) do
    {:noreply,
     socket
     |> assign(:show_cell_modal, false)
     |> assign(:cells, GameGrids.get_cells_for_grid(socket.assigns.game_grid.id))}
  end

  @impl true
  def handle_event("delete_cell", %{"id" => id}, socket) do
    cell = Enum.find(socket.assigns.cells, &(&1.id == id))
    {:ok, _} = GameGrids.delete_cell(cell)

    {:noreply,
     socket
     |> assign(:cells, GameGrids.get_cells_for_grid(socket.assigns.game_grid.id))
     |> put_flash(:info, "Cell deleted successfully")}
  end

  @impl true
  def handle_event("edit_cell", %{"id" => id}, socket) do
    cell = Enum.find(socket.assigns.cells, &(&1.id == id))
    points = cell.data["points"] || get_points(cell.row)

    {:noreply,
     socket
     |> assign(:show_cell_modal, true)
     |> assign(:selected_row, cell.row)
     |> assign(:selected_column, cell.column)
     |> assign(:points, points)
     |> assign(:editing_cell, cell)}
  end

  @impl true
  def handle_event("save_category", %{"category" => category, "phx-value-col" => col}, socket) do
    attrs = %{
      row: 1,
      column: String.to_integer(col),
      game_grid_id: socket.assigns.game_grid.id,
      data: %{"question" => category}
    }

    case GameGrids.create_cell(attrs) do
      {:ok, _cell} ->
        {:noreply,
         socket
         |> assign(:cells, GameGrids.get_cells_for_grid(socket.assigns.game_grid.id))
         |> put_flash(:info, "Category added successfully")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not add category")}
    end
  end

  defp page_title(:show), do: "Show Game grid"
  defp page_title(:edit), do: "Edit Game grid"

  defp get_cell(cells, row, col) do
    row = if is_binary(row), do: String.to_integer(row), else: row
    col = if is_binary(col), do: String.to_integer(col), else: col

    Enum.find(cells, fn cell ->
      cell.row == row && cell.column == col
    end)
  end

  defp get_points(row) do
    if row > 1, do: (row - 1) * 100, else: nil
  end
end
