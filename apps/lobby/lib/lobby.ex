defmodule Lobby do
  @moduledoc """
  Documentation for Lobby.
  """

  @doc """
  Connect to the lobby

  Creates an actor to maintain the player's session
  """
  def connect(name) do
    Lobby.Sessions.connect(%{name: name})
  end

  @doc """
  Disconnect from the lobby

  Clean up the player's session
  """
  def disconnect(session) do
    Lobby.Sessions.disconnect(session)
  end

  @doc """
  List games
  """
  def list_games do
    Lobby.Games.list()
  end

  @doc """
  Join game
  """
  def join({_, pid}, game_id) when is_atom(game_id) and is_pid(pid) do
    Lobby.Session.join(pid, game_id)
  end
end
