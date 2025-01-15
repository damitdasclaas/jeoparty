defmodule JeopartyWeb.GameGridLive.Index do
  use JeopartyWeb, :live_view

  alias Jeoparty.GameGrids
  alias Jeoparty.GameGrids.GameGrid

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:current_user, socket.assigns.current_user)
     |> stream(:game_grids, GameGrids.list_game_grids())}
    {:ok, stream(socket, :game_grids, GameGrids.list_game_grids())}
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
    socket
    |> assign(:page_title, "Listing Game grids")
    |> assign(:game_grid, nil)
  end

  @impl true
  def handle_info({JeopartyWeb.GameGridLive.FormComponent, {:saved, game_grid}}, socket) do
    {:noreply, stream_insert(socket, :game_grids, game_grid)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    game_grid = GameGrids.get_game_grid!(id)
    {:ok, _} = GameGrids.delete_game_grid(game_grid)

    {:noreply, stream_delete(socket, :game_grids, game_grid)}
  end
end
