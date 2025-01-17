defmodule JeopartyWeb.GameGridLive.Admin do
  use JeopartyWeb, :live_view
  import Ecto.Query
  alias Phoenix.PubSub

  alias Jeoparty.GameGrids
  alias Jeoparty.Games.Team
  alias Jeoparty.Repo

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket) do
      PubSub.subscribe(Jeoparty.PubSub, "game_grid:#{id}")
    end

    game_grid = GameGrids.get_game_grid!(id)
    cells = GameGrids.list_cells(game_grid)
    teams = Repo.all(from(t in Team, where: t.game_grid_id == ^game_grid.id, select: t))

    {:ok,
     socket
     |> assign(:game_grid, game_grid)
     |> assign(:cells, cells)
     |> assign(:teams, teams)
     |> assign(:revealed_cells, MapSet.new(game_grid.revealed_cell_ids || []))
     |> assign(:viewed_cell_id, game_grid.viewed_cell_id)
     |> assign(:show_cell_details, false)
     |> assign(:selected_cell, nil)}
  end

  @impl true
  def handle_event("add_team", _params, socket) do
    team_count = length(socket.assigns.teams) + 1
    team_name = "Team #{team_count}"

    {:ok, team} =
      %Team{}
      |> Team.changeset(%{
        name: team_name,
        game_grid_id: socket.assigns.game_grid.id
      })
      |> Repo.insert()

    {:noreply, assign(socket, :teams, socket.assigns.teams ++ [team])}
  end

  @impl true
  def handle_event("remove_team", %{"id" => id}, socket) do
    team = Enum.find(socket.assigns.teams, &(&1.id == String.to_integer(id)))
    {:ok, _} = Repo.delete(team)

    {:noreply,
     assign(socket, :teams, Enum.reject(socket.assigns.teams, &(&1.id == team.id)))}
  end

  @impl true
  def handle_event("adjust_score", %{"team_id" => team_id, "amount" => amount}, socket) do
    team = Enum.find(socket.assigns.teams, &(&1.id == String.to_integer(team_id)))
    amount = String.to_integer(amount)

    {:ok, updated_team} =
      team
      |> Team.changeset(%{score: team.score + amount})
      |> Repo.update()

    updated_teams =
      Enum.map(socket.assigns.teams, fn t ->
        if t.id == team.id, do: updated_team, else: t
      end)

    {:noreply, assign(socket, :teams, updated_teams)}
  end

  @impl true
  def handle_event("reveal_cell", %{"id" => id}, socket) do
    cell = Enum.find(socket.assigns.cells, &(&1.id == id))
    {:ok, game_grid} = GameGrids.reveal_cell(socket.assigns.game_grid, id)

    PubSub.broadcast(
      Jeoparty.PubSub,
      "game_grid:#{socket.assigns.game_grid.id}",
      {:reveal_cell, cell}
    )

    {:noreply,
     socket
     |> assign(:game_grid, game_grid)
     |> assign(:revealed_cells, MapSet.new(game_grid.revealed_cell_ids))}
  end

  @impl true
  def handle_event("hide_cell", %{"id" => id}, socket) do
    cell = Enum.find(socket.assigns.cells, &(&1.id == id))
    {:ok, game_grid} = GameGrids.hide_cell(socket.assigns.game_grid, id)

    PubSub.broadcast(
      Jeoparty.PubSub,
      "game_grid:#{socket.assigns.game_grid.id}",
      {:hide_cell, cell}
    )

    {:noreply,
     socket
     |> assign(:game_grid, game_grid)
     |> assign(:revealed_cells, MapSet.new(game_grid.revealed_cell_ids))}
  end

  @impl true
  def handle_event("hide_all", _params, socket) do
    {:ok, game_grid} = GameGrids.hide_all_cells(socket.assigns.game_grid)

    Enum.each(socket.assigns.cells, fn cell ->
      PubSub.broadcast(
        Jeoparty.PubSub,
        "game_grid:#{socket.assigns.game_grid.id}",
        {:hide_cell, cell}
      )
    end)

    {:noreply,
     socket
     |> assign(:game_grid, game_grid)
     |> assign(:revealed_cells, MapSet.new())
     |> assign(:viewed_cell_id, nil)}
  end

  @impl true
  def handle_event("view_cell", %{"id" => id}, socket) do
    cell = Enum.find(socket.assigns.cells, &(&1.id == id))

    if socket.assigns.viewed_cell_id == id do
      # If this cell is already being viewed, close it
      {:ok, game_grid} = GameGrids.set_viewed_cell(socket.assigns.game_grid, nil)

      PubSub.broadcast(
        Jeoparty.PubSub,
        "game_grid:#{socket.assigns.game_grid.id}",
        {:close_preview, nil}
      )

      {:noreply,
       socket
       |> assign(:game_grid, game_grid)
       |> assign(:viewed_cell_id, nil)}
    else
      # Show the new cell
      {:ok, game_grid} = GameGrids.set_viewed_cell(socket.assigns.game_grid, id)
      {:ok, game_grid} = GameGrids.reveal_cell(game_grid, id)

      PubSub.broadcast(
        Jeoparty.PubSub,
        "game_grid:#{socket.assigns.game_grid.id}",
        {:reveal_cell, cell}
      )

      PubSub.broadcast(
        Jeoparty.PubSub,
        "game_grid:#{socket.assigns.game_grid.id}",
        {:preview_cell, cell}
      )

      {:noreply,
       socket
       |> assign(:game_grid, game_grid)
       |> assign(:viewed_cell_id, id)
       |> assign(:revealed_cells, MapSet.new(game_grid.revealed_cell_ids))}
    end
  end

  @impl true
  def handle_event("show_cell_details", %{"id" => id}, socket) do
    cell = Enum.find(socket.assigns.cells, &(&1.id == id))

    {:noreply,
     socket
     |> assign(:selected_cell, cell)
     |> assign(:show_cell_details, true)}
  end

  @impl true
  def handle_event("close_modal", _, socket) do
    {:noreply,
     socket
     |> assign(:selected_cell, nil)
     |> assign(:show_cell_details, false)}
  end

  @impl true
  def handle_info({:cell_selected, cell}, socket) do
    {:noreply,
     socket
     |> assign(:revealed_cells, MapSet.put(socket.assigns.revealed_cells, cell.id))
     |> assign(:viewed_cell_id, cell.id)}
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

  @impl true
  def handle_info({:view_toggled, cell}, socket) do
    {:noreply, socket |> assign(:viewed_cell_id, cell && cell.id)}
  end

  defp get_cell(cells, row, col) do
    Enum.find(cells, fn cell ->
      cell.row == row && cell.column == col
    end)
  end
end
