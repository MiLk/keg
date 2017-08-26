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
  List sessions
  """
  def list do
    Lobby.Sessions.list()
  end
end
