defmodule ExboostWeb.Router do
  use ExboostWeb, :router

  import ExboostWeb.UserAuth

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, html: {ExboostWeb.Layouts, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(:fetch_current_user)
  end

  pipeline :api do
    plug(:accepts, ["json"])
    plug(:fetch_api_user)
  end

  scope "/", ExboostWeb do
    pipe_through(:browser)

    get("/", PageController, :home)
  end

  scope "/api", ExboostWeb do
    pipe_through(:api)

    # scope "/file" do
    #   post("/presigned", FileController, :presigned)
    #   post("/create", FileController, :create)
    #   post("/delete", FileController, :delete)
    # end

    # scope "/folder" do
    #   post("/create", FolderController, :create)
    #   post("/delete", FolderController, :delete)
    # end
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:exboost, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through(:browser)

      live_dashboard("/dashboard", metrics: ExboostWeb.Telemetry)
      forward("/mailbox", Plug.Swoosh.MailboxPreview)
    end
  end

  ## Authentication routes

  scope "/", ExboostWeb do
    pipe_through([:browser, :redirect_if_user_is_authenticated])

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{ExboostWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live("/users/register", UserRegistrationLive, :new)
      live("/users/log_in", UserLoginLive, :new)
      live("/users/reset_password", UserForgotPasswordLive, :new)
      live("/users/reset_password/:token", UserResetPasswordLive, :edit)
    end

    post("/users/log_in", UserSessionController, :create)
  end

  scope "/", ExboostWeb do
    pipe_through([:browser, :require_authenticated_user])

    live_session :require_authenticated_user,
      on_mount: [{ExboostWeb.UserAuth, :ensure_authenticated}] do
      live("/chat", ChatLive, :new)
      live("/chat/:id", ChatLive, :show)
      live("/resources", ResourcesLive, :index)
      live("/users/settings", UserSettingsLive, :edit)
      live("/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email)
    end
  end

  scope "/", ExboostWeb do
    pipe_through([:browser])

    delete("/users/log_out", UserSessionController, :delete)

    live_session :current_user,
      on_mount: [{ExboostWeb.UserAuth, :mount_current_user}] do
      live("/users/confirm/:token", UserConfirmationLive, :edit)
      live("/users/confirm", UserConfirmationInstructionsLive, :new)
    end
  end
end