defmodule Jeoparty.Teams do
  @moduledoc """
  The Teams context.
  """

  import Ecto.Query, warn: false
  alias Jeoparty.Repo
  alias Jeoparty.Teams.Team

  def list_teams_for_game(game_grid_id) do
    from(t in Team, where: t.game_grid_id == ^game_grid_id)
    |> Repo.all()
  end

  def get_team!(id), do: Repo.get!(Team, id)

  def create_team(attrs \\ %{}) do
    %Team{}
    |> Team.changeset(attrs)
    |> Repo.insert()
  end

  def update_team(%Team{} = team, attrs) do
    team
    |> Team.changeset(attrs)
    |> Repo.update()
  end

  def delete_team(%Team{} = team) do
    Repo.delete(team)
  end

  def change_team(%Team{} = team, attrs \\ %{}) do
    Team.changeset(team, attrs)
  end

  def add_points(%Team{} = team, points) when is_integer(points) do
    team
    |> Team.changeset(%{score: team.score + points})
    |> Repo.update()
  end

  def subtract_points(%Team{} = team, points) when is_integer(points) do
    team
    |> Team.changeset(%{score: team.score - points})
    |> Repo.update()
  end

  def reset_points(%Team{} = team) do
    team
    |> Team.changeset(%{score: 0})
    |> Repo.update()
  end
end
