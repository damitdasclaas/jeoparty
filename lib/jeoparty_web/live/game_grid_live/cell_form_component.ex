defmodule JeopartyWeb.GameGridLive.CellFormComponent do
  use JeopartyWeb, :live_component
  import Phoenix.HTML.Form

  alias Jeoparty.Question.Cell
  alias Jeoparty.GameGrids

  @impl true
  def render(assigns) do
    assigns = assign_new(assigns, :points, fn -> nil end)
    ~H"""
    <div>
      <.header>
        <%= header_text(assigns) %>
      </.header>

      <.simple_form
        for={@form}
        id="cell-form"
        phx-target={@myself}
        phx-submit="save"
        phx-change="validate"
      >
        <%= if !assigns[:selected_row] || assigns.selected_row != 1 do %>
          <.input
            field={@form[:type]}
            type="select"
            label="Type"
            prompt="Choose a type"
            options={[{"Text", "text"}, {"Picture", "picture"}, {"Video", "video"}]}
          />

          <%= case input_value(@form, :type) do %>
            <% "text" -> %>
              <.input
                field={@form[:question]}
                type="text"
                label="Question"
              />
            <% "picture" -> %>
              <.input
                field={@form[:question]}
                type="text"
                label="Question"
              />
              <.input
                field={@form[:image_url]}
                type="text"
                label="Image URL"
              />
            <% "video" -> %>
              <.input
                field={@form[:question]}
                type="text"
                label="Question"
              />
              <.input
                field={@form[:video_url]}
                type="text"
                label="Video URL"
                placeholder="YouTube or Vimeo URL"
              />
            <% _ -> %>
              <.input
                field={@form[:question]}
                type="text"
                label="Question"
              />
          <% end %>

          <.input
            field={@form[:points]}
            type="number"
            label="Points"
            value={@points}
          />
        <% else %>
          <.input
            field={@form[:question]}
            type="text"
            label="Category"
          />
        <% end %>
        <:actions>
          <.button phx-disable-with="Saving...">Save</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  defp header_text(%{selected_row: 1} = assigns) do
    if assigns.editing_cell, do: "Edit Category", else: "Add Category"
  end
  defp header_text(assigns) do
    if assigns.editing_cell, do: "Edit Question", else: "Add Question"
  end

  @impl true
  def update(assigns, socket) do
    initial_params = if assigns[:editing_cell] do
      %{
        "type" => assigns.editing_cell.type,
        "question" => assigns.editing_cell.data["question"],
        "points" => assigns.editing_cell.data["points"],
        "image_url" => assigns.editing_cell.data["image_url"]
      }
    else
      %{
        "type" => "text",
        "question" => "",
        "points" => assigns[:points],
        "image_url" => ""
      }
    end

    changeset = Cell.changeset(%Cell{}, initial_params)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:editing_cell, assigns[:editing_cell])
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"cell" => params}, socket) do
    changeset =
      %Cell{}
      |> Cell.changeset(params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("save", %{"cell" => params}, socket) do
    IO.inspect(params, label: "Save Params")

    attrs = %{
      row: socket.assigns.row,
      column: socket.assigns.column,
      game_grid_id: socket.assigns.game_grid_id,
      type: params["type"] || "text",
      data: %{
        "question" => params["question"],
        "points" => if(params["points"] == "", do: nil, else: params["points"]),
        "image_url" => params["image_url"]
      }
    }

    IO.inspect(attrs, label: "Final Attrs")

    if socket.assigns.editing_cell do
      update_cell(socket.assigns.editing_cell, attrs, socket)
    else
      create_cell(attrs, socket)
    end
  end

  defp create_cell(attrs, socket) do
    case GameGrids.create_cell(attrs) do
      {:ok, _cell} ->
        send(self(), {:cell_created})
        {:noreply,
         socket
         |> put_flash(:info, "Cell created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        error_message = get_changeset_error(changeset)
        {:noreply,
         socket
         |> put_flash(:error, error_message)
         |> assign_form(changeset)}
    end
  end

  defp update_cell(cell, attrs, socket) do
    case GameGrids.update_cell(cell, attrs) do
      {:ok, _cell} ->
        send(self(), {:cell_created})
        {:noreply,
         socket
         |> put_flash(:info, "Cell updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        error_message = get_changeset_error(changeset)
        {:noreply,
         socket
         |> put_flash(:error, error_message)
         |> assign_form(changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "cell")
    assign(socket, :form, form)
  end

  # Helper to get a friendly error message from the changeset
  defp get_changeset_error(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.map(fn {_key, value} -> value end)
    |> List.first()
    |> case do
      nil -> "Could not save cell"
      message -> message
    end
  end
end
