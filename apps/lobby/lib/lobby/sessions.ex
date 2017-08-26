defmodule Lobby.Sessions do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    {:ok, %{ sessions: %{} }}
  end

  # Client

  def connect(args) do
    GenServer.call(__MODULE__, {:connect, args})
  end

  def disconnect(pid) when is_pid(pid) do
    GenServer.cast(pid, :disconnect)
  end
  def disconnect(uuid) do
    case GenServer.call(__MODULE__, {:get_pid, uuid}) do
      {:ok, pid} -> disconnect(pid)
      :error -> {:error, :no_session_found}
    end
  end

  def list do
    GenServer.call(__MODULE__, :list)
  end

  # Server

  def handle_call({:connect, args}, _from, state = %{sessions: sessions}) do
    uuid = generate_uuid(sessions)
    case Map.fetch(sessions, uuid) do
      {:ok, pid} -> {:reply, {:reconnected, uuid, pid}, state}
      :error ->
        {status, pid} =
          case Supervisor.start_child(Lobby.Sessions.Supervisor, [uuid, args]) do
            {:ok, pid} -> {:connected, pid}
            {:error, {:already_started, pid}} -> {:reconnected, pid}
            {:error, error} ->
              error |> IO.inspect()
             {:error, nil}
          end
        new_state = case pid do
          nil -> state
          _ -> Kernel.put_in(state, [:sessions, uuid], pid)
        end
        {:reply, {status, uuid, pid}, new_state}
    end
  end

  def handle_call({:get_pid, uuid}, _from, state = %{sessions: sessions}) do
    {:reply, Map.fetch(sessions, uuid), state}
  end

  def handle_call(:list, _from, state = %{sessions: sessions}) do
    {:reply, Map.keys(sessions), state}
  end

  def handle_cast({:remove, uuid}, state) do
    {_pid, new_state} = Kernel.pop_in(state, [:sessions, uuid])
    {:noreply, new_state}
  end

  # Helpers

  defp generate_uuid(sessions) do
    uuid = UUID.uuid4()
    if Map.has_key?(sessions, uuid) do
      generate_uuid(sessions)
    else
      uuid
    end
  end
end

defmodule Lobby.Sessions.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    import Supervisor.Spec, warn: false

    children = [worker(Lobby.Sessions.Session, [], restart: :transient)]
    opts = [strategy: :simple_one_for_one, name: __MODULE__]
    supervise(children, opts)
  end
end

defmodule Lobby.Sessions.Session do
  use GenServer

  def start_link(uuid, args) do
    GenServer.start_link(__MODULE__, [uuid, args], name: Module.concat(__MODULE__, uuid))
  end

  def init([uuid, args]) do
    {:ok, Map.put(args, :uuid, uuid)}
  end

  def handle_cast(:disconnect, state) do
    :ok = GenServer.cast(Lobby.Sessions, {:remove, Map.fetch!(state, :uuid)})
    {:stop, :normal, state}
  end
end
