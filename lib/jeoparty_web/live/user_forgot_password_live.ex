defmodule JeopartyWeb.UserForgotPasswordLive do
  use JeopartyWeb, :live_view

  alias Jeoparty.Accounts

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm">
      <.header class="text-center text-gray-200">
        Forgot your password?
        <:subtitle class="text-gray-400">We'll send a password reset link to your inbox</:subtitle>
      </.header>

      <.simple_form for={@form} id="reset_password_form" phx-submit="send_email" class="bg-gray-800 rounded-lg p-6 shadow-lg border border-gray-700">
        <.input field={@form[:email]} type="email" placeholder="Email" required class="bg-gray-700 text-gray-200 border-gray-600" />
        <:actions>
          <.button phx-disable-with="Sending..." class="w-full bg-blue-600 hover:bg-blue-700">
            Send password reset instructions
          </.button>
        </:actions>
      </.simple_form>
      <p class="text-center text-sm mt-4 text-gray-400">
        <.link href={~p"/users/register"} class="text-blue-400 hover:text-blue-300 hover:underline">Register</.link>
        | <.link href={~p"/users/log_in"} class="text-blue-400 hover:text-blue-300 hover:underline">Log in</.link>
      </p>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, form: to_form(%{}, as: "user"))}
  end

  def handle_event("send_email", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_user_reset_password_instructions(
        user,
        &url(~p"/users/reset_password/#{&1}")
      )
    end

    info =
      "If your email is in our system, you will receive instructions to reset your password shortly."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> redirect(to: ~p"/")}
  end
end
