defmodule JeopartyWeb.GameGridLive.Show do
  use JeopartyWeb, :live_view

  alias Jeoparty.GameGrids

  @impl true
  def mount(_params, _session, socket) do
    socket = assign(socket, :current_user, socket.assigns.current_user)
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:game_grid, GameGrids.get_game_grid!(id))}
  end

  defp page_title(:show), do: "Show Game grid"
  defp page_title(:edit), do: "Edit Game grid"
end
