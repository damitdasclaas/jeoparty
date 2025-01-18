defmodule JeopartyWeb.GameGridLive.Admin do
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
     |> assign(:viewed_cell_id, game_grid.viewed_cell_id)
     |> assign(:show_cell_details, false)
     |> assign(:selected_cell, nil)
     |> assign(:new_team_name, "")
     |> assign(:page_title, "Admin View - #{game_grid.name}")}
  end

  @impl true
  def handle_event("show_cell_details", %{"id" => cell_id}, socket) do
    cell = Enum.find(socket.assigns.cells, &(&1.id == cell_id))
    {:noreply, socket |> assign(:show_cell_details, true) |> assign(:selected_cell, cell)}
  end

  @impl true
  def handle_event("close_modal", _, socket) do
    {:noreply, socket |> assign(:show_cell_details, false) |> assign(:selected_cell, nil)}
  end

  @impl true
  def handle_event("reveal_cell", %{"id" => cell_id}, socket) do
    cell = Enum.find(socket.assigns.cells, &(&1.id == cell_id))
    {:ok, game_grid} = GameGrids.reveal_cell(socket.assigns.game_grid, cell_id)

    PubSub.broadcast(Jeoparty.PubSub, "game_grid:#{socket.assigns.game_grid.id}", {:reveal_cell, cell})

    {:noreply,
     socket
     |> assign(:game_grid, game_grid)
     |> assign(:revealed_cells, MapSet.new(game_grid.revealed_cell_ids))}
  end

  @impl true
  def handle_event("hide_cell", %{"id" => cell_id}, socket) do
    cell = Enum.find(socket.assigns.cells, &(&1.id == cell_id))
    {:ok, game_grid} = GameGrids.hide_cell(socket.assigns.game_grid, cell_id)

    PubSub.broadcast(Jeoparty.PubSub, "game_grid:#{socket.assigns.game_grid.id}", {:hide_cell, cell})

    {:noreply,
     socket
     |> assign(:game_grid, game_grid)
     |> assign(:revealed_cells, MapSet.new(game_grid.revealed_cell_ids))}
  end

  @impl true
  def handle_event("hide_all", _params, socket) do
    {:ok, game_grid} = GameGrids.hide_all_cells(socket.assigns.game_grid)

    Enum.each(socket.assigns.cells, fn cell ->
      PubSub.broadcast(Jeoparty.PubSub, "game_grid:#{socket.assigns.game_grid.id}", {:hide_cell, cell})
    end)

    {:noreply,
     socket
     |> assign(:game_grid, game_grid)
     |> assign(:revealed_cells, MapSet.new())
     |> assign(:viewed_cell_id, nil)}
  end

  @impl true
  def handle_event("reset_game", _params, socket) do
    # First hide all cells
    {:ok, game_grid} = GameGrids.hide_all_cells(socket.assigns.game_grid)

    # Reset all team scores
    Enum.each(socket.assigns.teams, fn team ->
      Teams.reset_points(team)
    end)

    # Broadcast reset event to all clients
    PubSub.broadcast(Jeoparty.PubSub, "game_grid:#{socket.assigns.game_grid.id}", :reset_game)

    # Close any open previews
    PubSub.broadcast(Jeoparty.PubSub, "game_grid:#{socket.assigns.game_grid.id}", {:close_preview, nil})

    teams = Teams.list_teams_for_game(socket.assigns.game_grid.id)

    {:noreply,
     socket
     |> assign(:game_grid, game_grid)
     |> assign(:revealed_cells, MapSet.new())
     |> assign(:viewed_cell_id, nil)
     |> assign(:show_cell_details, false)
     |> assign(:selected_cell, nil)
     |> assign(:teams, teams)}
  end

  @impl true
  def handle_event("view_cell", %{"id" => cell_id}, socket) do
    cell = Enum.find(socket.assigns.cells, &(&1.id == cell_id))

    if socket.assigns.viewed_cell_id == cell_id do
      # If this cell is already being viewed, close it
      {:ok, game_grid} = GameGrids.set_viewed_cell(socket.assigns.game_grid, nil)
      PubSub.broadcast(Jeoparty.PubSub, "game_grid:#{socket.assigns.game_grid.id}", {:close_preview, nil})

      {:noreply,
       socket
       |> assign(:game_grid, game_grid)
       |> assign(:viewed_cell_id, nil)}
    else
      # Show the new cell
      {:ok, game_grid} = GameGrids.set_viewed_cell(socket.assigns.game_grid, cell_id)
      {:ok, game_grid} = GameGrids.reveal_cell(game_grid, cell_id)

      PubSub.broadcast(Jeoparty.PubSub, "game_grid:#{socket.assigns.game_grid.id}", {:reveal_cell, cell})
      PubSub.broadcast(Jeoparty.PubSub, "game_grid:#{socket.assigns.game_grid.id}", {:preview_cell, cell})

      {:noreply,
       socket
       |> assign(:game_grid, game_grid)
       |> assign(:viewed_cell_id, cell_id)
       |> assign(:revealed_cells, MapSet.new(game_grid.revealed_cell_ids))}
    end
  end

  # Team management events
  @impl true
  def handle_event("add_team", %{"team" => %{"name" => name}}, socket) when name != "" do
    case Teams.create_team(%{name: name, game_grid_id: socket.assigns.game_grid.id}) do
      {:ok, _team} ->
        teams = Teams.list_teams_for_game(socket.assigns.game_grid.id)
        {:noreply, socket |> assign(:teams, teams) |> assign(:new_team_name, "")}

      {:error, _changeset} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("add_team", _, socket), do: {:noreply, socket}

  @impl true
  def handle_event("delete_team", %{"id" => team_id}, socket) do
    team = Teams.get_team!(team_id)
    {:ok, _} = Teams.delete_team(team)
    teams = Teams.list_teams_for_game(socket.assigns.game_grid.id)
    {:noreply, assign(socket, :teams, teams)}
  end

  @impl true
  def handle_event("add_points", %{"id" => team_id, "points" => points}, socket) do
    team = Teams.get_team!(team_id)
    {:ok, _team} = Teams.add_points(team, String.to_integer(points))
    teams = Teams.list_teams_for_game(socket.assigns.game_grid.id)
    {:noreply, assign(socket, :teams, teams)}
  end

  @impl true
  def handle_event("subtract_points", %{"id" => team_id, "points" => points}, socket) do
    team = Teams.get_team!(team_id)
    case Teams.subtract_points(team, String.to_integer(points)) do
      {:ok, _team} ->
        teams = Teams.list_teams_for_game(socket.assigns.game_grid.id)
        {:noreply, assign(socket, :teams, teams)}
      {:error, :score_below_zero} ->
        {:noreply, socket}
    end
  end

  defp get_cell(cells, row, col) do
    row = if is_binary(row), do: String.to_integer(row), else: row
    col = if is_binary(col), do: String.to_integer(col), else: col

    Enum.find(cells, fn cell ->
      cell.row == row && cell.column == col
    end)
  end
end
