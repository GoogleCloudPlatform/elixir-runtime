defmodule MinimalPhoenix14Web do
  def controller do
    quote do
      use Phoenix.Controller, namespace: MinimalPhoenix14Web

      import Plug.Conn
      import MinimalPhoenix14Web.Gettext
      alias MinimalPhoenix14Web.Router.Helpers, as: Routes
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "lib/minimal_phoenix14_web/templates",
        namespace: MinimalPhoenix14Web

      import Phoenix.Controller, only: [get_flash: 1, get_flash: 2, view_module: 1]

      use Phoenix.HTML

      import MinimalPhoenix14Web.ErrorHelpers
      import MinimalPhoenix14Web.Gettext
      alias MinimalPhoenix14Web.Router.Helpers, as: Routes
    end
  end

  def router do
    quote do
      use Phoenix.Router
      import Plug.Conn
      import Phoenix.Controller
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      import MinimalPhoenix14Web.Gettext
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
