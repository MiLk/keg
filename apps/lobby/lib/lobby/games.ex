defmodule Lobby.Games do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    {:ok, %{} }
  end

  # Client

  def register(id, pid) do
    GenServer.cast(__MODULE__, {:register_game, id, pid})
  end

  def list do
    GenServer.call(__MODULE__, :list_games)
  end

  def join(game_id) do
    GenServer.call(__MODULE__, {:join, game_id})
  end

  # Server

  def handle_call(:list_games, _from, state) do
    {:reply, Map.keys(state), state}
  end

  def handle_call({:join, game_id}, {sid, _tag}, state) do
    case Map.fetch(state, game_id) do
      {:ok, %{queue: q}} ->
        new_state = Kernel.put_in(state, [game_id, :queue], Qex.push(q, sid))
        GenServer.cast(self(), {:match, game_id})
        {:reply, :ok, new_state}
      _ ->
        {:reply, :invalid_game, state}
    end
  end

  def handle_cast({:register_game, id, pid}, state) do
    {:noreply, Map.put(state, id, %{pid: pid, queue: Qex.new() })}
  end

  def handle_cast({:match, game_id}, state) do
    case Map.fetch(state, game_id) do
      {:ok, %{pid: pid, queue: q}} ->
        with {{:value, p1}, q1} <- Qex.pop(q),
             {{:value, p2}, q2} <- Qex.pop(q1) do
          {:before, q, :after, q2}
          case GenServer.call(pid, {:create, [p1, p2], []}) do
            {_uuid, _game_pid} ->
              :ok = GenServer.cast(self(), {:match, game_id})
              {:noreply, Kernel.put_in(state, [game_id, :queue], q2)}
            _ ->
             {:noreply, state}
          end
          |> IO.inspect()
        else
          _ -> {:noreply, state}
        end
      _ ->
        {:noreply, state}
     end
  end

end
