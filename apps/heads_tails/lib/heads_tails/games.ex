defmodule HeadsTails.Games do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    Lobby.Games.register(:heads_and_tails, self())
    {:ok, %{}}
  end

  # Client

  # Server

  def handle_call({:create, players, opts}, _from, state) do
    uuid = generate_uuid(state)
    case Supervisor.start_child(HeadsTails.Games.Supervisor, [uuid, players, opts]) do
      {:ok, pid} ->
        new_state = Map.put(state, uuid, pid)
        {:reply, {uuid, pid}, new_state}
      {:error, error} ->
        error |> IO.inspect()
       {:reply, :error, state}
    end
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

defmodule HeadsTails.Games.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    import Supervisor.Spec, warn: false

    children = [worker(HeadsTails.Game, [], restart: :transient)]
    opts = [strategy: :simple_one_for_one, name: __MODULE__]
    supervise(children, opts)
  end
end
