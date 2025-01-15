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
  def handle_event("update_category", %{"value" => category, "col" => col}, socket) do
    if String.trim(category) == "" do
      {:noreply, socket}
    else
      cell_params = %{
        "row" => 1,
        "column" => String.to_integer(col),
        "data" => %{"question" => category},
        "game_grid_id" => socket.assigns.game_grid.id,
        "is_category" => true,
        "type" => "text"
      }

      case get_cell(socket.assigns.cells, 1, String.to_integer(col)) do
        nil ->
          {:ok, cell} = GameGrids.create_cell(cell_params)
          {:noreply,
           socket
           |> assign(:cells, [cell | socket.assigns.cells])
           |> put_flash(:info, "Category added")}

        existing_cell ->
          {:ok, updated_cell} = GameGrids.update_cell(existing_cell, %{data: %{"question" => category}})
          updated_cells = Enum.map(socket.assigns.cells, fn cell ->
            if cell.id == existing_cell.id, do: updated_cell, else: cell
          end)
          {:noreply,
           socket
           |> assign(:cells, updated_cells)
           |> put_flash(:info, "Category updated")}
      end
    end
  end

  @impl true
  def handle_event("modal-closed", _, socket) do
    {:noreply,
     socket
     |> assign(:show_cell_modal, false)
     |> assign(:selected_row, nil)
     |> assign(:selected_column, nil)
     |> assign(:editing_cell, nil)
     |> assign(:points, nil)}
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
     |> assign(:selected_row, nil)
     |> assign(:selected_column, nil)
     |> assign(:editing_cell, nil)
     |> assign(:points, nil)
     |> assign(:cells, GameGrids.get_cells_for_grid(socket.assigns.game_grid.id))}
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

  defp truncate_text(text, length \\ 15) do
    if String.length(text) > length do
      String.slice(text, 0, length) <> "..."
    else
      text
    end
  end

  def handle_event("delete_category", %{"id" => id}, socket) do
    cell = Enum.find(socket.assigns.cells, &(&1.id == id))
    {:ok, _} = GameGrids.delete_cell(cell)

    {:noreply,
     socket
     |> assign(:cells, GameGrids.get_cells_for_grid(socket.assigns.game_grid.id))
     |> put_flash(:info, "Category deleted")}
  end

  @impl true
  def handle_event("handle_category_keyup", %{"key" => key, "target" => %{"value" => value}, "phx-value-col" => col}, socket) do
    if key == "Enter" and String.trim(value) != "" do
      handle_event("update_category", %{"value" => value, "col" => col}, socket)
    else
      {:noreply, socket}
    end
  end

  def handle_event("handle_category_keyup", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("save_category", %{"category" => category, "col" => col}, socket) do
    if String.trim(category) != "" do
      handle_event("update_category", %{"value" => category, "col" => col}, socket)
    else
      {:noreply, socket}
    end
  end
end
