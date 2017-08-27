defmodule Lobby.Session do
    @moduledoc false

  use GenServer

  def start_link(uuid, pid, args) do
    GenServer.start_link(__MODULE__, [uuid, pid, args], name: Module.concat(__MODULE__, uuid))
  end

  def init([uuid, pid, args]) do
    {:ok, Map.merge(args, %{
      uuid: uuid,
      client_pid: pid,
    })}
  end

  # Client

  def join(pid, game_id) do
    GenServer.call(pid, {:join, game_id})
  end

  def notify(pid, msg) do
    GenServer.cast(pid, {:notify, msg})
  end

  # Server

  def handle_call({:join, game_id}, _from, state) do
    reply = Lobby.Games.join(game_id)
    {:reply, reply, state}
  end

  def handle_cast(:disconnect, state) do
    :ok = GenServer.cast(Lobby.Sessions, {:remove, Map.fetch!(state, :uuid)})
    {:stop, :normal, state}
  end

  def handle_cast({:notify, msg}, state = %{client_pid: pid}) do
    Kernel.send(pid, msg)
    {:noreply, state}
  end
end
