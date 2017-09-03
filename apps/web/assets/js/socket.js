import {Socket} from "phoenix"

const socket = new Socket("/socket");

socket.connect();
const lobby = socket.channel("lobby");

const joinGame = name => () => {
  lobby.push("join_game", {game: name});
};

const gameUiEl = document.getElementById("game-ui");
gameUiEl.style.display = "none";
lobby.on("new game", ({gameId}) => {
  console.log(`A new game (${gameId}) has started.`);
  gameUiEl.style.display = "block";
});

const tossBtnEl = document.getElementById("toss");
tossBtnEl.onclick = () => {
  lobby.push("toss");
};

const scoreEl = document.getElementById("score");
const updateScore = ({result, score: [s1, s2]}) => {
  const el = document.createElement("span");
  el.textContent = `${s1} / ${s2}`;
  el.style.color = result === 'won' ? 'green' : 'red';
  if (scoreEl.firstChild) {
    scoreEl.replaceChild(el, scoreEl.firstChild);
  } else {
    scoreEl.appendChild(el);
  }
};
lobby.on("score", updateScore);

const gameListEl = document.getElementById("game-list");
const updateGameList = ({games}) => {
  // Clear the list
  while (gameListEl.firstChild) {
    gameListEl.removeChild(gameListEl.firstChild);
  }
  // Add the game names
  games.forEach(name => {
    const el = document.createElement("li");
    el.textContent = name;
    el.onclick = joinGame(name);
    gameListEl.appendChild(el);
  });
};

const lobbyJoined = resp => {
  console.log("Joined successfully", resp);

  lobby.push("list_games")
    .receive("ok", updateGameList);
};

lobby.join()
  .receive("ok", lobbyJoined)
  .receive("error", resp => { console.log("Unable to join", resp) });

export default socket;
