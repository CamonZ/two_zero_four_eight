// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import "../css/app.scss";

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import deps with the dep name or local files with a relative path, for example:
//
//     import {Socket} from "phoenix"
//     import socket from "./socket"
//
import "phoenix_html";
import { Socket } from "phoenix";

let gamesRe = /^\/games\/.+/;

let keysMap = {
  37: "left",
  38: "up",
  39: "right",
  40: "down",
};

const clearTiles = function () {
  let tilesContainer = document.getElementsByClassName("tile-container")[0];
  tilesContainer.innerHTML = "";
};

const addTile = function (position, value) {
  const textNode = document.createTextNode(value);
  let innerTile = document.createElement("div");
  innerTile.className = "tile-inner rev";
  innerTile.appendChild(textNode);

  let tile = document.createElement("div");
  tile.className = `tile tile-${value} tile-position-${position}`;
  tile.appendChild(innerTile);

  let tilesContainer = document.getElementsByClassName("tile-container")[0];
  tilesContainer.appendChild(tile);
};

if (window.location.pathname.match(gamesRe)) {
  const parts = window.location.pathname.split("/");
  const slug = parts[parts.length - 1];
  const socket = new Socket("ws://localhost:4000/socket");
  socket.connect();

  const channel = socket.channel(`games:${slug}`);
  channel.join();

  channel.on("moved", (state) => {
    clearTiles();
    for (const [position, value] of Object.entries(state)) {
      addTile(position, value);
    }
  });

  channel.on("game_won", () => {
    let winContainer = document.getElementById("win-container");
    winContainer.className = "";
  });

  document.addEventListener("keydown", (ev) => {
    const modifiers =
      event.altKey || event.ctrlKey || event.metaKey || event.shitKey;
    const direction = keysMap[event.which];

    if (!modifiers && direction !== undefined) {
      event.preventDefault();
      channel.push("move", { direction: direction });
    }
  });
}
