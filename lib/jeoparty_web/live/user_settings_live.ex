defmodule JeopartyWeb.UserSettingsLive do
  use JeopartyWeb, :live_view

  alias Jeoparty.Accounts

  def render(assigns) do
    ~H"""
    <.header class="bg-gray-900">
      <div class="flex items-center justify-between">
        <div class="flex items-center gap-4">
          <h1 class="text-lg font-medium text-gray-400">Account Settings</h1>
          <.link
            navigate={~p"/game_grids"}
            class="px-3 py-1 rounded-lg bg-gray-700 hover:bg-gray-600 text-gray-300 hover:text-gray-200 text-sm transition-colors flex items-center gap-2"
          >
            <.icon name="hero-home" class="h-4 w-4"/>
            Home
          </.link>
        </div>
      </div>
    </.header>

    <div class="container mx-auto px-4 py-8">
      <div class="max-w-2xl mx-auto space-y-12 divide-y divide-gray-700">
        <div class="pt-4">
          <h2 class="text-lg font-medium text-gray-200 mb-4">Email Settings</h2>
          <.simple_form
            for={@email_form}
            id="email_form"
            phx-submit="update_email"
            phx-change="validate_email"
            class="bg-gray-800 rounded-lg p-6 shadow-lg border border-gray-700"
          >
            <.input field={@email_form[:email]} type="email" label="Email" required class="bg-gray-700 text-gray-200 border-gray-600" />
            <.input
              field={@email_form[:current_password]}
              name="current_password"
              id="current_password_for_email"
              type="password"
              label="Current password"
              value={@email_form_current_password}
              required
              class="bg-gray-700 text-gray-200 border-gray-600"
            />
            <:actions>
              <.button phx-disable-with="Changing..." class="bg-blue-600 hover:bg-blue-700">Change Email</.button>
            </:actions>
          </.simple_form>
        </div>
        <div class="pt-8">
          <h2 class="text-lg font-medium text-gray-200 mb-4">Password Settings</h2>
          <.simple_form
            for={@password_form}
            id="password_form"
            action={~p"/users/log_in?_action=password_updated"}
            method="post"
            phx-change="validate_password"
            phx-submit="update_password"
            phx-trigger-action={@trigger_submit}
            class="bg-gray-800 rounded-lg p-6 shadow-lg border border-gray-700"
          >
            <input
              name={@password_form[:email].name}
              type="hidden"
              id="hidden_user_email"
              value={@current_email}
            />
            <.input field={@password_form[:password]} type="password" label="New password" required class="bg-gray-700 text-gray-200 border-gray-600" />
            <.input
              field={@password_form[:password_confirmation]}
              type="password"
              label="Confirm new password"
              class="bg-gray-700 text-gray-200 border-gray-600"
            />
            <.input
              field={@password_form[:current_password]}
              name="current_password"
              type="password"
              label="Current password"
              id="current_password_for_password"
              value={@current_password}
              required
              class="bg-gray-700 text-gray-200 border-gray-600"
            />
            <:actions>
              <.button phx-disable-with="Changing..." class="bg-blue-600 hover:bg-blue-700">Change Password</.button>
            </:actions>
          </.simple_form>
        </div>
      </div>
    </div>
    """
  end

  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_user_email(socket.assigns.current_user, token) do
        :ok ->
          put_flash(socket, :info, "Email changed successfully.")

        :error ->
          put_flash(socket, :error, "Email change link is invalid or it has expired.")
      end

    {:ok, push_navigate(socket, to: ~p"/users/settings")}
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    email_changeset = Accounts.change_user_email(user)
    password_changeset = Accounts.change_user_password(user)

    socket =
      socket
      |> assign(:current_password, nil)
      |> assign(:email_form_current_password, nil)
      |> assign(:current_email, user.email)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:trigger_submit, false)

    {:ok, socket}
  end

  def handle_event("validate_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    email_form =
      socket.assigns.current_user
      |> Accounts.change_user_email(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form, email_form_current_password: password)}
  end

  def handle_event("update_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.apply_user_email(user, password, user_params) do
      {:ok, applied_user} ->
        Accounts.deliver_user_update_email_instructions(
          applied_user,
          user.email,
          &url(~p"/users/settings/confirm_email/#{&1}")
        )

        info = "A link to confirm your email change has been sent to the new address."
        {:noreply, socket |> put_flash(:info, info) |> assign(email_form_current_password: nil)}

      {:error, changeset} ->
        {:noreply, assign(socket, :email_form, to_form(Map.put(changeset, :action, :insert)))}
    end
  end

  def handle_event("validate_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    password_form =
      socket.assigns.current_user
      |> Accounts.change_user_password(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form, current_password: password)}
  end

  def handle_event("update_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, user} ->
        password_form =
          user
          |> Accounts.change_user_password(user_params)
          |> to_form()

        {:noreply, assign(socket, trigger_submit: true, password_form: password_form)}

      {:error, changeset} ->
        {:noreply, assign(socket, password_form: to_form(changeset))}
    end
  end
end
