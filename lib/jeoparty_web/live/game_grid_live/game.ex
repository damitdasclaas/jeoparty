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
     |> assign(:selected_answer, nil)
     |> assign(:selected_answers, game_grid.selected_answers || %{})
     |> assign(:page_title, "Game View - #{game_grid.name}")}
  end

  @impl true
  def handle_event("select_cell", %{"id" => cell_id}, socket) do
    cell = Enum.find(socket.assigns.cells, &(&1.id == cell_id))

    if cell && !cell.is_category do
      {game_grid, revealed_cells} = if MapSet.member?(socket.assigns.revealed_cells, cell_id) do
        {socket.assigns.game_grid, socket.assigns.revealed_cells}
      else
        {:ok, game_grid} = GameGrids.reveal_cell(socket.assigns.game_grid, cell_id)
        PubSub.broadcast(Jeoparty.PubSub, "game_grid:#{socket.assigns.game_grid.id}", {:reveal_cell, cell})
        {game_grid, MapSet.new(game_grid.revealed_cell_ids)}
      end

      selected_answer = Map.get(socket.assigns.selected_answers, cell_id)

      {:ok, game_grid} = GameGrids.set_viewed_cell(game_grid, cell_id)
      PubSub.broadcast(Jeoparty.PubSub, "game_grid:#{socket.assigns.game_grid.id}", {:view_toggled, cell})
      PubSub.broadcast(Jeoparty.PubSub, "game_grid:#{socket.assigns.game_grid.id}", {:preview_cell, cell})

      {:noreply,
       socket
       |> assign(:game_grid, game_grid)
       |> assign(:revealed_cells, revealed_cells)
       |> assign(:show_modal, true)
       |> assign(:selected_cell, cell)
       |> assign(:selected_answer, selected_answer)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("select_answer", %{"option" => option, "cell-id" => cell_id}, socket) do
    selected_option = String.to_integer(option)

    if is_nil(Map.get(socket.assigns.selected_answers, cell_id)) do
      new_selected_answers = Map.put(socket.assigns.selected_answers, cell_id, selected_option)
      {:ok, game_grid} = GameGrids.update_game_grid(socket.assigns.game_grid, %{selected_answers: new_selected_answers})

      {:noreply,
       socket
       |> assign(:game_grid, game_grid)
       |> assign(:selected_answer, selected_option)
       |> assign(:selected_answers, new_selected_answers)}
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
     |> assign(:selected_cell, nil)
     |> assign(:selected_answer, nil)}
  end

  @impl true
  def handle_info({:cell_selected, cell}, socket) do
    {game_grid, revealed_cells} = if MapSet.member?(socket.assigns.revealed_cells, cell.id) do
      {socket.assigns.game_grid, socket.assigns.revealed_cells}
    else
      {:ok, game_grid} = GameGrids.reveal_cell(socket.assigns.game_grid, cell.id)
      {game_grid, MapSet.new(game_grid.revealed_cell_ids)}
    end

    selected_answer = Map.get(socket.assigns.selected_answers, cell.id)

    {:noreply,
     socket
     |> assign(:game_grid, game_grid)
     |> assign(:revealed_cells, revealed_cells)
     |> assign(:show_modal, true)
     |> assign(:selected_cell, cell)
     |> assign(:selected_answer, selected_answer)}
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

    new_selected_answers = Map.delete(socket.assigns.selected_answers, cell.id)
    {:ok, game_grid} = GameGrids.update_game_grid(game_grid, %{selected_answers: new_selected_answers})

    {:noreply,
     socket
     |> assign(:game_grid, game_grid)
     |> assign(:revealed_cells, MapSet.new(game_grid.revealed_cell_ids))
     |> assign(:selected_answers, new_selected_answers)}
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
    {:ok, game_grid} = GameGrids.update_game_grid(socket.assigns.game_grid, %{selected_answers: %{}})

    {:noreply,
     socket
     |> assign(:game_grid, game_grid)
     |> assign(:revealed_cells, MapSet.new())
     |> assign(:show_modal, false)
     |> assign(:selected_cell, nil)
     |> assign(:selected_answers, %{})}
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

  @impl true
  def handle_info({:teams_updated, teams}, socket) do
    {:noreply, assign(socket, :teams, teams)}
  end

  @impl true
  def handle_info({:view_toggled, _}, socket) do
    {:noreply,
     socket
     |> assign(:show_modal, false)
     |> assign(:selected_cell, nil)}
  end

  @impl true
  def handle_info({:reload_game_view, _}, socket) do
    {:noreply,
     socket
     |> push_event("reload_page", %{})}
  end

  defp get_cell(cells, row, col) do
    row = if is_binary(row), do: String.to_integer(row), else: row
    col = if is_binary(col), do: String.to_integer(col), else: col

    Enum.find(cells, fn cell ->
      cell.row == row && cell.column == col
    end)
  end
end
