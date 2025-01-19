defmodule JeopartyWeb.UserLoginLive do
  use JeopartyWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm">
      <.header class="text-center text-gray-200">
        Log in to account
        <:subtitle class="text-gray-400">
          Don't have an account?
          <.link navigate={~p"/users/register"} class="font-semibold text-blue-400 hover:text-blue-300 hover:underline">
            Sign up
          </.link>
          for an account now.
        </:subtitle>
      </.header>

      <.simple_form for={@form} id="login_form" action={~p"/users/log_in"} phx-update="ignore" class="bg-gray-800 rounded-lg p-6 shadow-lg border border-gray-700">
        <.input field={@form[:email]} type="email" label="Email" required class="bg-gray-700 text-gray-200 border-gray-600" />
        <.input field={@form[:password]} type="password" label="Password" required class="bg-gray-700 text-gray-200 border-gray-600" />

        <:actions>
          <div class="flex items-center justify-between w-full">
            <.input field={@form[:remember_me]} type="checkbox" label="Keep me logged in" class="text-gray-200" />
            <.link href={~p"/users/reset_password"} class="text-sm font-semibold text-blue-400 hover:text-blue-300 hover:underline">
              Forgot your password?
            </.link>
          </div>
        </:actions>
        <:actions>
          <.button phx-disable-with="Logging in..." class="w-full bg-blue-600 hover:bg-blue-700">
            Log in <span aria-hidden="true">→</span>
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    email = Phoenix.Flash.get(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "user")
    {:ok, assign(socket, form: form), temporary_assigns: [form: form]}
  end
end
