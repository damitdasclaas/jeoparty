defmodule Jeoparty.Question.Cell do
  use Ecto.Schema
  import Ecto.Changeset
  alias JeopartyWeb.EmbedConverter

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @cell_types ["text", "picture", "video"]

  schema "question_cells" do
    field :data, :map
    field :column, :integer
    field :row, :integer
    field :is_category, :boolean, default: false
    field :type, :string, default: "text"
    belongs_to :game_grid, Jeoparty.GameGrids.GameGrid

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(cell, attrs) do
    cell
    |> cast(attrs, [:row, :column, :data, :game_grid_id, :is_category, :type])
    |> validate_required([:row, :column, :game_grid_id])
    |> validate_inclusion(:type, @cell_types)
    |> maybe_set_category()
    |> transform_video_url()
    |> unique_constraint([:game_grid_id, :row, :column],
      name: :question_cells_position_index,
      message: "A cell already exists at this position")
  end

  defp transform_video_url(changeset) do
    if get_field(changeset, :type) == "video" do
      case get_change(changeset, :data) do
        %{"video_url" => url} when is_binary(url) ->
          data = get_change(changeset, :data)
          put_change(changeset, :data, %{data | "video_url" => EmbedConverter.transform_video_url(url)})
        _ -> changeset
      end
    else
      changeset
    end
  end

  def types, do: @cell_types

  defp maybe_set_category(changeset) do
    case get_field(changeset, :row) do
      1 -> put_change(changeset, :is_category, true)
      _ -> changeset
    end
  end
end
