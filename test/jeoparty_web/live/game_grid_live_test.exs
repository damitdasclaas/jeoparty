defmodule JeopartyWeb.GameGridLiveTest do
  use JeopartyWeb.ConnCase

  import Phoenix.LiveViewTest
  import Jeoparty.GameGridsFixtures

  @create_attrs %{name: "some name", columns: 42, rows: 42}
  @update_attrs %{name: "some updated name", columns: 43, rows: 43}
  @invalid_attrs %{name: nil, columns: nil, rows: nil}

  defp create_game_grid(_) do
    game_grid = game_grid_fixture()
    %{game_grid: game_grid}
  end

  describe "Index" do
    setup [:create_game_grid]

    test "lists all game_grids", %{conn: conn, game_grid: game_grid} do
      {:ok, _index_live, html} = live(conn, ~p"/game_grids")

      assert html =~ "Listing Game grids"
      assert html =~ game_grid.name
    end

    test "saves new game_grid", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/game_grids")

      assert index_live |> element("a", "New Game grid") |> render_click() =~
               "New Game grid"

      assert_patch(index_live, ~p"/game_grids/new")

      assert index_live
             |> form("#game_grid-form", game_grid: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#game_grid-form", game_grid: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/game_grids")

      html = render(index_live)
      assert html =~ "Game grid created successfully"
      assert html =~ "some name"
    end

    test "updates game_grid in listing", %{conn: conn, game_grid: game_grid} do
      {:ok, index_live, _html} = live(conn, ~p"/game_grids")

      assert index_live |> element("#game_grids-#{game_grid.id} a", "Edit") |> render_click() =~
               "Edit Game grid"

      assert_patch(index_live, ~p"/game_grids/#{game_grid}/edit")

      assert index_live
             |> form("#game_grid-form", game_grid: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#game_grid-form", game_grid: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/game_grids")

      html = render(index_live)
      assert html =~ "Game grid updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes game_grid in listing", %{conn: conn, game_grid: game_grid} do
      {:ok, index_live, _html} = live(conn, ~p"/game_grids")

      assert index_live |> element("#game_grids-#{game_grid.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#game_grids-#{game_grid.id}")
    end
  end

  describe "Show" do
    setup [:create_game_grid]

    test "displays game_grid", %{conn: conn, game_grid: game_grid} do
      {:ok, _show_live, html} = live(conn, ~p"/game_grids/#{game_grid}")

      assert html =~ "Show Game grid"
      assert html =~ game_grid.name
    end

    test "updates game_grid within modal", %{conn: conn, game_grid: game_grid} do
      {:ok, show_live, _html} = live(conn, ~p"/game_grids/#{game_grid}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Game grid"

      assert_patch(show_live, ~p"/game_grids/#{game_grid}/show/edit")

      assert show_live
             |> form("#game_grid-form", game_grid: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#game_grid-form", game_grid: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/game_grids/#{game_grid}")

      html = render(show_live)
      assert html =~ "Game grid updated successfully"
      assert html =~ "some updated name"
    end
  end
end
