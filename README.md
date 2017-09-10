# Keg

## Getting started

* `docker build -t ${USER}/keg:latest -f docker/Dockerfile.build .`
* `docker push ${USER}/keg`

## Example

```elixir
s1 = Lobby.connect(:alice)
s2 = Lobby.connect(:bob)
games = Lobby.list_games()
Lobby.join(s1, Enum.at(games, 0))
Lobby.join(s2, Enum.at(games, 0))
{uuid, game_pid} = receive do
  {:new_game, msg} -> msg
end
flush()
HeadsTails.Game.toss(game_pid)
flush()
HeadsTails.Game.toss(game_pid)
flush()
HeadsTails.Game.toss(game_pid)
flush()
HeadsTails.Game.toss(game_pid)
flush()
HeadsTails.Game.finish(game_pid)
```
