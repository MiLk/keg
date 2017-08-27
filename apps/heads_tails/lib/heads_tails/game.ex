defmodule HeadsTails.Game do
  use GenServer

  def start_link(uuid, players, opts) do
    GenServer.start_link(__MODULE__, [uuid, players, opts], name: Module.concat(__MODULE__, uuid))
  end

  def init([uuid, players = [p1, p2], _opts]) do
    Lobby.Session.notify(p1, {:new_game, {uuid, self()}})
    Lobby.Session.notify(p2, {:new_game, {uuid, self()}})
    {:ok, %{
      uuid: uuid,
      players: players,
      score: {0, 0}
    }}
  end

  # Client

  def finish(pid) do
    GenServer.cast(pid, :finish)
  end

  def toss(pid) do
    GenServer.cast(pid, :toss)
  end

  # Server

  def handle_cast(:toss, state = %{players: [p1, p2], score: {s1, s2}}) do
    {m1, m2, score} = if :rand.uniform() > 0.5 do
      {:win, :lose, {s1 + 1, s2}}
    else
      {:lose, :win, {s1, s2 + 1}}
    end
    Lobby.Session.notify(p1, {m1, score})
    Lobby.Session.notify(p2, {m2, score})
    {:noreply, Map.put(state, :score, score)}
  end

  def handle_cast(:finish, state) do
    :ok = GenServer.cast(HeadsTails.Games, {:remove, Map.fetch!(state, :uuid)})
    {:stop, :normal, state}
  end

end
