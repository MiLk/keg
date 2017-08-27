defmodule Lobby.Sessions do
  @moduledoc false

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

  def handle_call({:connect, args}, {client_pid, _tag}, state = %{sessions: sessions}) do
    uuid = generate_uuid(sessions)
    case Supervisor.start_child(Lobby.Sessions.Supervisor, [uuid, client_pid, args]) do
      {:ok, pid} ->
        new_state = Kernel.put_in(state, [:sessions, uuid], pid)
        {:reply, {uuid, pid}, new_state}
      {:error, error} ->
        error |> IO.inspect()
       {:reply, :error, state}
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
  @moduledoc false

  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    import Supervisor.Spec, warn: false

    children = [worker(Lobby.Session, [], restart: :transient)]
    opts = [strategy: :simple_one_for_one, name: __MODULE__]
    supervise(children, opts)
  end
end
