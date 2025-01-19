defmodule JeopartyWeb.GameGridLive.CellFormComponent do
  use JeopartyWeb, :live_component
  import Phoenix.HTML.Form
  alias Phoenix.LiveView.Upload

  alias Jeoparty.Question.Cell
  alias Jeoparty.GameGrids
  alias JeopartyWeb.EmbedConverter

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(show_source: false, image_input_type: "url", video_input_type: "url")
     |> allow_upload(:image_upload,
        accept: ~w(.jpg .jpeg .png .gif),
        max_entries: 1,
        max_file_size: 10_000_000
     )
     |> allow_upload(:video_upload,
        accept: ~w(.mp4 .webm .mov),
        max_entries: 1,
        max_file_size: 50_000_000  # 50MB limit for videos
     )}
  end

  @impl true
  def render(assigns) do
    assigns = assign_new(assigns, :points, fn -> nil end)
    ~H"""
    <div class="max-w-2xl mx-auto bg-white dark:bg-gray-800 rounded-xl p-6">
      <.header class="mb-8">
        <%= header_text(assigns) %>
      </.header>

      <.simple_form
        for={@form}
        id="cell-form"
        phx-target={@myself}
        phx-submit="save"
        phx-change="validate"
        class="space-y-6"
      >
        <%= if !assigns[:selected_row] || assigns.selected_row != 1 do %>
          <div class="bg-gray-50 dark:bg-gray-900 rounded-lg p-4 border border-gray-100 dark:border-gray-700">
            <.input
              field={@form[:type]}
              type="select"
              label="Type"
              prompt="Choose a type"
              options={[{"Text", "text"}, {"Picture", "picture"}, {"Video", "video"}]}
              class="w-full"
            />
          </div>

          <%= case input_value(@form, :type) do %>
            <% "text" -> %>
              <div class="bg-gray-50 dark:bg-gray-900 rounded-lg p-4 border border-gray-100 dark:border-gray-700">
                <.input
                  field={@form[:question]}
                  type="text"
                  label="Question"
                />
              </div>
            <% "picture" -> %>
              <div class="bg-gray-50 dark:bg-gray-900 rounded-lg p-4 space-y-4 border border-gray-100 dark:border-gray-700">
                <.input
                  field={@form[:question]}
                  type="text"
                  label="Question"
                />

                <div class="flex items-center gap-4 mb-4">
                  <label class="text-sm font-medium">Image Source:</label>
                  <div class="flex items-center gap-2">
                    <label class="inline-flex items-center">
                      <input
                        type="radio"
                        name="image_input_type"
                        value="url"
                        checked={@image_input_type == "url"}
                        phx-click="toggle_image_input"
                        phx-target={@myself}
                        class="form-radio"
                      />
                      <span class="ml-2">URL</span>
                    </label>
                    <label class="inline-flex items-center ml-4">
                      <input
                        type="radio"
                        name="image_input_type"
                        value="upload"
                        checked={@image_input_type == "upload"}
                        phx-click="toggle_image_input"
                        phx-target={@myself}
                        class="form-radio"
                      />
                      <span class="ml-2">Upload</span>
                    </label>
                  </div>
                </div>

                <%= if @image_input_type == "url" do %>
                  <.input
                    field={@form[:image_url]}
                    type="text"
                    label="Image URL"
                  />
                  <% image_url = Phoenix.HTML.Form.input_value(@form, :image_url) %>
                  <%= if image_url && image_url != "" do %>
                    <div class="mt-4 rounded-lg overflow-hidden shadow-lg">
                      <img src={get_image_url(image_url)} alt="Preview" class="w-full h-48 object-cover"/>
                    </div>
                  <% end %>
                <% else %>
                  <div class="mt-2 space-y-4">
                    <.live_file_input upload={@uploads.image_upload} class="w-full" />

                    <%= for entry <- @uploads.image_upload.entries do %>
                      <div class="space-y-4">
                        <div class="mt-4 rounded-lg overflow-hidden shadow-lg">
                          <.live_img_preview entry={entry} class="w-full h-48 object-cover" />
                        </div>

                        <%= for err <- upload_errors(@uploads.image_upload, entry) do %>
                          <div class="mt-1 text-red-500 text-sm"><%= error_to_string(err) %></div>
                        <% end %>
                      </div>
                    <% end %>

                    <%= if @editing_cell && @editing_cell.data["image_url"] && String.starts_with?(@editing_cell.data["image_url"], "/uploads/") do %>
                      <div class="mt-4 rounded-lg overflow-hidden shadow-lg">
                        <img src={@editing_cell.data["image_url"]} alt="Current Image" class="w-full h-48 object-cover"/>
                        <div class="bg-gray-100 dark:bg-gray-700 p-2 text-sm text-center text-gray-600 dark:text-gray-300">
                          Current Image
                        </div>
                      </div>
                    <% end %>

                    <%= for err <- upload_errors(@uploads.image_upload) do %>
                      <div class="mt-1 text-red-500 text-sm"><%= error_to_string(err) %></div>
                    <% end %>
                  </div>
                <% end %>
              </div>
            <% "video" -> %>
              <div class="bg-gray-50 dark:bg-gray-900 rounded-lg p-4 space-y-4 border border-gray-100 dark:border-gray-700">
                <.input
                  field={@form[:question]}
                  type="text"
                  label="Question"
                />

                <div class="flex items-center gap-4 mb-4">
                  <label class="text-sm font-medium">Video Source:</label>
                  <div class="flex items-center gap-2">
                    <label class="inline-flex items-center">
                      <input
                        type="radio"
                        name="video_input_type"
                        value="url"
                        checked={@video_input_type == "url"}
                        phx-click="toggle_video_input"
                        phx-target={@myself}
                        class="form-radio"
                      />
                      <span class="ml-2">URL</span>
                    </label>
                    <label class="inline-flex items-center ml-4">
                      <input
                        type="radio"
                        name="video_input_type"
                        value="upload"
                        checked={@video_input_type == "upload"}
                        phx-click="toggle_video_input"
                        phx-target={@myself}
                        class="form-radio"
                      />
                      <span class="ml-2">Upload</span>
                    </label>
                  </div>
                </div>

                <%= if @video_input_type == "url" do %>
                  <.input
                    field={@form[:video_url]}
                    type="text"
                    label="Video URL"
                    placeholder="YouTube or Vimeo URL recommended"
                  />
                  <div class="mt-1 text-sm text-gray-500 dark:text-gray-400">
                    For best results, use YouTube or Vimeo links. Other platforms may have inconsistent behavior.
                  </div>
                  <% video_url = Phoenix.HTML.Form.input_value(@form, :video_url) %>
                  <%= if video_url && video_url != "" do %>
                    <div class="mt-4 rounded-lg overflow-hidden shadow-lg bg-gray-100 dark:bg-gray-900">
                      <div class="aspect-w-16 aspect-h-9">
                        <%= case EmbedConverter.convert_url(video_url) do %>
                          <% {:ok, embed_url} -> %>
                            <iframe
                              src={embed_url}
                              class="w-full h-full"
                              frameborder="0"
                              allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
                              allowfullscreen
                            ></iframe>
                          <% {:error, _} -> %>
                            <div class="p-4 text-center text-gray-600 dark:text-gray-400">
                              Video preview not available. Please check if the URL is correct.
                            </div>
                        <% end %>
                      </div>
                    </div>
                  <% end %>
                <% else %>
                  <div class="mt-2 space-y-4">
                    <.live_file_input upload={@uploads.video_upload} class="w-full" />

                    <%= for entry <- @uploads.video_upload.entries do %>
                      <div class="space-y-4">
                        <div class="mt-4 rounded-lg overflow-hidden shadow-lg bg-gray-100 dark:bg-gray-900">
                          <div class="p-4 text-center text-gray-600 dark:text-gray-400">
                            Selected video: <%= entry.client_name %>
                          </div>
                        </div>

                        <%= for err <- upload_errors(@uploads.video_upload, entry) do %>
                          <div class="mt-1 text-red-500 text-sm"><%= error_to_string(err) %></div>
                        <% end %>
                      </div>
                    <% end %>

                    <%= if @editing_cell && @editing_cell.data["video_url"] && String.starts_with?(@editing_cell.data["video_url"], "/uploads/") do %>
                      <div class="mt-4 rounded-lg overflow-hidden shadow-lg">
                        <video controls class="w-full">
                          <source src={@editing_cell.data["video_url"]} type="video/mp4">
                          Your browser does not support the video tag.
                        </video>
                        <div class="bg-gray-100 dark:bg-gray-700 p-2 text-sm text-center text-gray-600 dark:text-gray-300">
                          Current Video
                        </div>
                      </div>
                    <% end %>

                    <%= for err <- upload_errors(@uploads.video_upload) do %>
                      <div class="mt-1 text-red-500 text-sm"><%= error_to_string(err) %></div>
                    <% end %>
                  </div>
                <% end %>
              </div>
            <% _ -> %>
              <div class="bg-gray-50 dark:bg-gray-900 rounded-lg p-4 border border-gray-100 dark:border-gray-700">
                <.input
                  field={@form[:question]}
                  type="text"
                  label="Question"
                />
              </div>
          <% end %>

          <div class="bg-gray-50 dark:bg-gray-900 rounded-lg p-4 space-y-4 border border-gray-100 dark:border-gray-700">
            <.input
              field={@form[:answer]}
              type="text"
              label="Answer"
            />

            <div class="flex items-center gap-2">
              <.input
                field={@form[:show_source]}
                type="checkbox"
                label="Add answer source URL"
                phx-click="toggle_source"
                phx-target={@myself}
                checked={@show_source}
              />
            </div>

            <%= if @show_source do %>
              <div class="pl-4 border-l-2 border-gray-200 dark:border-gray-700">
                <.input
                  field={@form[:answer_source_url]}
                  type="text"
                  label="Answer Source URL"
                  placeholder="URL to verify the answer"
                />
              </div>
            <% end %>

            <.input
              field={@form[:points]}
              type="number"
              label="Points"
              value={@points}
            />
          </div>
        <% else %>
          <div class="bg-gray-50 dark:bg-gray-900 rounded-lg p-4 border border-gray-100 dark:border-gray-700">
            <.input
              field={@form[:question]}
              type="text"
              label="Category"
            />
          </div>
        <% end %>
        <:actions>
          <.button phx-disable-with="Saving..." class="w-full bg-blue-600 hover:bg-blue-700">Save</.button>
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
      image_url = assigns.editing_cell.data["image_url"]
      video_url = assigns.editing_cell.data["video_url"]
      image_input_type = if image_url && String.starts_with?(image_url, "/uploads/"), do: "upload", else: "url"
      video_input_type = if video_url && String.starts_with?(video_url, "/uploads/"), do: "upload", else: "url"

      %{
        "type" => assigns.editing_cell.type,
        "question" => assigns.editing_cell.data["question"],
        "points" => assigns.editing_cell.data["points"],
        "image_url" => if(image_input_type == "url", do: image_url, else: ""),
        "video_url" => if(video_input_type == "url", do: video_url, else: ""),
        "answer" => assigns.editing_cell.data["answer"],
        "answer_source_url" => assigns.editing_cell.data["answer_source_url"]
      }
    else
      %{
        "type" => "text",
        "question" => "",
        "points" => assigns[:points],
        "image_url" => "",
        "video_url" => "",
        "answer" => "",
        "answer_source_url" => ""
      }
    end

    changeset = Cell.changeset(%Cell{}, initial_params)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:editing_cell, assigns[:editing_cell])
     |> assign(:image_input_type, if(assigns[:editing_cell], do: if(String.starts_with?(assigns.editing_cell.data["image_url"] || "", "/uploads/"), do: "upload", else: "url"), else: "url"))
     |> assign(:video_input_type, if(assigns[:editing_cell], do: if(String.starts_with?(assigns.editing_cell.data["video_url"] || "", "/uploads/"), do: "upload", else: "url"), else: "url"))
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("toggle_source", _, socket) do
    {:noreply, assign(socket, show_source: !socket.assigns.show_source)}
  end

  @impl true
  def handle_event("toggle_image_input", %{"value" => type}, socket) do
    {:noreply, assign(socket, image_input_type: type)}
  end

  @impl true
  def handle_event("toggle_video_input", %{"value" => type}, socket) do
    {:noreply, assign(socket, video_input_type: type)}
  end

  @impl true
  def handle_event("validate", params, socket) do
    changeset =
      %Cell{}
      |> Cell.changeset(params["cell"] || %{})
      |> Map.put(:action, :validate)

    {:noreply,
     socket
     |> assign_form(changeset)
     |> validate_upload()}
  end

  @impl true
  def handle_event("save", %{"cell" => params}, socket) do
    uploaded_image_url = handle_image_upload(socket)
    uploaded_video_url = handle_video_upload(socket)

    # Determine final image URL based on input type and uploads
    image_url = case socket.assigns.image_input_type do
      "upload" -> uploaded_image_url || (socket.assigns[:editing_cell] && socket.assigns.editing_cell.data["image_url"])
      _ -> params["image_url"]
    end

    # Determine final video URL based on input type and uploads
    video_url = case socket.assigns.video_input_type do
      "upload" -> uploaded_video_url || (socket.assigns[:editing_cell] && socket.assigns.editing_cell.data["video_url"])
      _ -> params["video_url"]
    end

    attrs = %{
      row: socket.assigns.row,
      column: socket.assigns.column,
      game_grid_id: socket.assigns.game_grid_id,
      type: params["type"] || "text",
      data: %{
        "question" => params["question"],
        "points" => if(params["points"] == "", do: nil, else: params["points"]),
        "image_url" => image_url,
        "video_url" => video_url,
        "answer" => params["answer"],
        "answer_source_url" => params["answer_source_url"]
      }
    }

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

  defp handle_image_upload(socket) do
    case socket.assigns.image_input_type do
      "upload" ->
        case uploaded_entries(socket, :image_upload) do
          [] ->
            # If no new upload and editing existing cell, preserve the existing image
            if socket.assigns[:editing_cell], do: socket.assigns.editing_cell.data["image_url"], else: nil
          _entries ->
            consume_uploaded_entries(socket, :image_upload, fn %{path: path}, entry ->
              dest = Path.join(["priv", "static", "uploads", filename(entry)])
              File.mkdir_p!(Path.dirname(dest))
              File.cp!(path, dest)
              {:ok, "/uploads/" <> filename(entry)}
            end)
            |> List.first()
        end
      _ ->
        nil
    end
  end

  defp handle_video_upload(socket) do
    case socket.assigns.video_input_type do
      "upload" ->
        case uploaded_entries(socket, :video_upload) do
          [] ->
            # If no new upload and editing existing cell, preserve the existing video
            if socket.assigns[:editing_cell], do: socket.assigns.editing_cell.data["video_url"], else: nil
          _entries ->
            consume_uploaded_entries(socket, :video_upload, fn %{path: path}, entry ->
              dest = Path.join(["priv", "static", "uploads", filename(entry)])
              File.mkdir_p!(Path.dirname(dest))
              File.cp!(path, dest)
              {:ok, "/uploads/" <> filename(entry)}
            end)
            |> List.first()
        end
      _ ->
        nil
    end
  end

  defp filename(entry) do
    [ext | _] = MIME.extensions(entry.client_type)
    "#{entry.uuid}.#{ext}"
  end

  defp validate_upload(socket) do
    socket
    |> validate_image_upload()
    |> validate_video_upload()
  end

  defp validate_image_upload(socket) do
    case socket.assigns.image_input_type do
      "upload" ->
        {socket, valid?} =
          Enum.reduce(socket.assigns.uploads.image_upload.entries, {socket, true}, fn entry, {socket, _valid?} ->
            case entry.client_type do
              type when type in ~w(image/jpeg image/png image/gif) ->
                {socket, true}
              _other ->
                {socket
                 |> put_flash(:error, "Invalid file type. Please upload a JPG, PNG, or GIF."),
                 false}
            end
          end)
        if valid?, do: socket, else: cancel_upload(socket, :image_upload)
      _ ->
        socket
    end
  end

  defp validate_video_upload(socket) do
    case socket.assigns.video_input_type do
      "upload" ->
        {socket, valid?} =
          Enum.reduce(socket.assigns.uploads.video_upload.entries, {socket, true}, fn entry, {socket, _valid?} ->
            case entry.client_type do
              type when type in ~w(video/mp4 video/webm video/quicktime) ->
                {socket, true}
              _other ->
                {socket
                 |> put_flash(:error, "Invalid file type. Please upload an MP4, WebM, or MOV file."),
                 false}
            end
          end)
        if valid?, do: socket, else: cancel_upload(socket, :video_upload)
      _ ->
        socket
    end
  end

  defp cancel_upload(socket, upload_name) do
    Enum.reduce(socket.assigns.uploads[upload_name].entries, socket, fn entry, socket ->
      Phoenix.LiveView.cancel_upload(socket, upload_name, entry.ref)
    end)
  end

  defp error_to_string(:too_large), do: "File is too large"
  defp error_to_string(:too_many_files), do: "Too many files"
  defp error_to_string(:not_accepted), do: "Unacceptable file type"

  # New helper function to handle image URLs
  defp get_image_url(url) when is_binary(url) do
    cond do
      String.starts_with?(url, "/uploads/") ->
        url  # The URL is already correct as configured in endpoint.ex
      String.starts_with?(url, ["http://", "https://"]) ->
        url  # External URL, use as is
      true ->
        nil  # Invalid URL format
    end
  end
  defp get_image_url(_), do: nil
end
