defmodule ExboostWeb.UserSettingsLive do
  use ExboostWeb, :live_view
  alias Exboost.Accounts
  alias Exboost.Accounts.User

  def render(assigns) do
    ~H"""
    <.header class="text-center">
      Account Settings
      <:subtitle>Manage your account email address and password settings</:subtitle>
    </.header>

    <div class="space-y-12 divide-y">
      <div>
        <.simple_form
          for={@llm_form}
          id="lm_form"
          phx-submit="update_llm"
          phx-trigger-action={@trigger_submit}
        >
          <p>Fill in all the fields in this section to remove the rate limit.</p>
          <.input field={@llm_form[:llm_model]} type="text" label="OpenAI-compatible API model" />
          <.input field={@llm_form[:llm_base_url]} type="text" label="OpenAI-compatible API base URL" />
          <.input field={@llm_form[:llm_api_key]} type="password" label="OpenAI-compatible API key" />
          <.input
            field={@llm_form[:search_engine]}
            type="select"
            label="Search API"
            options={["exa", "serper"]}
          />
          <.input field={@llm_form[:search_api_key]} type="password" label="Search API key" />
          <:actions>
            <div class="flex flex-row space-x-2">
              <.button type="submit" phx-disable-with="Updating...">Update</.button>
              <.button type="button" phx-click="reset_llm" phx-disable-with="Resetting...">
                Reset
              </.button>
            </div>
          </:actions>
        </.simple_form>
      </div>
      <div>
        <.simple_form
          for={@email_form}
          id="email_form"
          phx-submit="update_email"
          phx-change="validate_email"
        >
          <.input field={@email_form[:email]} type="email" label="Email" required />
          <.input
            field={@email_form[:current_password]}
            name="current_password"
            id="current_password_for_email"
            type="password"
            label="Current password"
            value={@email_form_current_password}
            required
          />
          <:actions>
            <.button phx-disable-with="Changing...">Change Email</.button>
          </:actions>
        </.simple_form>
      </div>
      <div>
        <.simple_form
          for={@password_form}
          id="password_form"
          action={~p"/users/log_in?_action=password_updated"}
          method="post"
          phx-change="validate_password"
          phx-submit="update_password"
          phx-trigger-action={@trigger_submit}
        >
          <input
            name={@password_form[:email].name}
            type="hidden"
            id="hidden_user_email"
            value={@current_email}
          />
          <.input field={@password_form[:password]} type="password" label="New password" required />
          <.input
            field={@password_form[:password_confirmation]}
            type="password"
            label="Confirm new password"
          />
          <.input
            field={@password_form[:current_password]}
            name="current_password"
            type="password"
            label="Current password"
            id="current_password_for_password"
            value={@current_password}
            required
          />
          <:actions>
            <.button phx-disable-with="Changing...">Change Password</.button>
          </:actions>
        </.simple_form>
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
    llm_changeset = User.llm_changeset(user)
    api_key = nil

    socket =
      socket
      |> assign(:current_password, nil)
      |> assign(:email_form_current_password, nil)
      |> assign(:current_email, user.email)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:llm_form, to_form(llm_changeset))
      |> assign(:trigger_submit, false)
      |> assign(:api_key, api_key)

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

  def handle_event("generate_api_key", _params, socket) do
    user = socket.assigns.current_user
    api_key = Accounts.create_user_api_token(user)
    {:noreply, assign(socket, api_key: api_key)}
  end

  def handle_event("update_llm", %{"user" => params}, socket) do
    user = socket.assigns.current_user

    case Accounts.update_user_llm(user, params) do
      {:ok, user} ->
        llm_changeset = User.llm_changeset(user)

        {:noreply,
         socket
         |> put_flash(:info, "LLM settings updated")
         |> assign(current_user: user)
         |> assign(llm_form: to_form(llm_changeset))}

      {:error, _changeset} ->
        llm_changeset = User.llm_changeset(user)

        {:noreply,
         socket
         |> put_flash(:error, "Failed to update LLM settings")
         |> assign(llm_form: to_form(llm_changeset))}
    end
  end

  def handle_event("reset_llm", _params, socket) do
    llm_changeset =
      case Accounts.reset_user_llm(socket.assigns.current_user) do
        {:ok, user} ->
          User.llm_changeset(user)

        _ ->
          %{}
      end

    {:noreply, assign(socket, :llm_form, to_form(llm_changeset))}
  end
end
