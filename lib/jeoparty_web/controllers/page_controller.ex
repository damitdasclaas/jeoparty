defmodule JeopartyWeb.PageController do
  use JeopartyWeb, :controller

  def redirect_to_game_grids(conn, _params) do
    redirect(conn, to: ~p"/game_grids")
  end
end
