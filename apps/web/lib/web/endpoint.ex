defmodule Web.Endpoint do
  use Phoenix.Endpoint, otp_app: :web

  socket "/socket", Web.UserSocket
  socket "/wobserver", Wobserver.Web.PhoenixSocket

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phoenix.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/", from: :web, gzip: false,
    only: ~w(css fonts images js favicon.ico robots.txt)

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
  end

  plug Plug.RequestId
  plug Plug.Logger

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Poison

  plug Plug.MethodOverride
  plug Plug.Head

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  plug Plug.Session,
    store: :cookie,
    key: "_web_key",
    signing_salt: "SgucjNhA"

  plug Web.Router

  @doc """
  Callback invoked for dynamically configuring the endpoint.

  It receives the endpoint configuration and checks if
  configuration should be loaded from the system environment.
  """
  def init(_key, config) do
    if config[:load_from_system_env] do
      env =
        [:port, :url_port, :host, :secret_key_base]
        |> Enum.map(&{&1, get_env!(&1)})
        |> Map.new

      {
        :ok,
        config
        |> Keyword.put(:http, [port: env.port])
        |> Keyword.put(:url, [host: env.host, port: env.url_port])
        |> Keyword.put(:secret_key_base, env.secret_key_base)
      }
    else
      {:ok, config}
    end
  end

  defp get_env!(name) when is_atom(name) do
    name
    |> Atom.to_string
    |> String.upcase
    |> get_env!
  end
  defp get_env!(name) when is_bitstring(name) do
    System.get_env(name) || raise "expected the #{name} environment variable to be set"
  end
end
