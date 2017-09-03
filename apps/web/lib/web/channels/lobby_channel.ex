defmodule Web.LobbyChannel do
  use Phoenix.Channel

  def join("lobby", _message, socket) do
    session = Lobby.connect(:user)
    socket = assign(socket, :session, session)
    {:ok, socket}
  end

  # Messages from the websockets
  def handle_in("list_games", _payload, socket) do
    games = Lobby.list_games()
    {:reply, {:ok, %{games: games}}, socket}
  end

  def handle_in("join_game", %{"game" => game}, socket) do
    reply = socket
      |> get_session
      |> Lobby.join(String.to_existing_atom(game))
    {:reply, reply, socket}
  end

  def handle_in("toss", _payload, socket) do
    {_uuid, game_pid} = Map.fetch!(socket.assigns, :game)
    reply = HeadsTails.Game.toss(game_pid)
    {:reply, reply, socket}
  end

  # Messages from the backend
  def handle_info({:new_game, game = {uuid, _game_pid}}, socket) do
    socket = assign(socket, :game, game)
    push(socket, "new game", %{"gameId" => uuid})
    {:noreply, socket}
  end

  def handle_info({:won, score}, socket) do
    push(socket, "score", %{result: :won, score: Tuple.to_list(score)})
    {:noreply, socket}
  end

  def handle_info({:lost, score}, socket) do
    push(socket, "score", %{result: :lost, score: Tuple.to_list(score)})
    {:noreply, socket}
  end

  defp get_session(%Phoenix.Socket{assigns: %{ session: session }}) do
    session
  end
end
