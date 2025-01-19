defmodule JeopartyWeb.GameGridLive.FormComponent do
  use JeopartyWeb, :live_component

  alias Jeoparty.GameGrids

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage game_grid records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="game_grid-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:columns]} type="number" label="Columns" min="1" />
        <.input
          field={@form[:rows]}
          type="number"
          label="Rows"
          min="2"
          help="First row is reserved for categories. Minimum 2 rows required."
        />
        <.input field={@form[:created_by]} type="hidden" value={@current_user.id} />
        <:actions>
          <.button phx-disable-with="Saving...">Save Game grid</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{game_grid: game_grid} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(GameGrids.change_game_grid(game_grid))
     end)}
  end

  @impl true
  def handle_event("validate", %{"game_grid" => game_grid_params}, socket) do
    changeset = GameGrids.change_game_grid(socket.assigns.game_grid, game_grid_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"game_grid" => game_grid_params}, socket) do
    save_game_grid(socket, socket.assigns.action, game_grid_params)
  end

  defp save_game_grid(socket, :edit, game_grid_params) do
    case GameGrids.update_game_grid(socket.assigns.game_grid, game_grid_params) do
      {:ok, game_grid} ->
        notify_parent({:saved, game_grid})

        {:noreply,
         socket
         |> put_flash(:info, "Game grid updated successfully")
         |> push_patch(to: get_return_path(socket))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_game_grid(socket, :new, game_grid_params) do
    case GameGrids.create_game_grid(game_grid_params) do
      {:ok, game_grid} ->
        notify_parent({:saved, game_grid})

        {:noreply,
         socket
         |> put_flash(:info, "Game grid created successfully")
         |> push_patch(to: get_return_path(socket))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp get_return_path(socket) do
    if Map.has_key?(socket.assigns, :return_to) do
      socket.assigns.return_to
    else
      socket.assigns.patch
    end
  end
end
