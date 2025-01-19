// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

// Define hooks
const Hooks = {
  GameView: {
    mounted() {
      this.handleViewTransition(true);
      this.lastView = this.el.querySelector("#leaderboard") ? "standings" : "grid";
    },
    updated() {
      const currentView = this.el.querySelector("#leaderboard") ? "standings" : "grid";
      if (currentView !== this.lastView) {
        this.handleViewTransition(true);
        this.lastView = currentView;
      }
    },
    handleViewTransition(animate = false) {
      const grid = this.el.querySelector("table");
      const standings = this.el.querySelector("#leaderboard")?.parentElement;
      
      if (grid && animate) {
        grid.style.opacity = "0";
        requestAnimationFrame(() => {
          grid.style.opacity = "1";
          grid.classList.add("game-grid");
          const cells = grid.querySelectorAll("td > div");
          cells.forEach((cell, index) => {
            cell.classList.add("grid-cell");
            cell.style.setProperty('--delay', `${index * 0.05}s`);
          });
        });
      }
      
      if (standings && animate) {
        standings.style.opacity = "0";
        requestAnimationFrame(() => {
          standings.style.opacity = "1";
          standings.classList.add("standings-view");
          const teams = standings.querySelectorAll("#leaderboard > div");
          teams.forEach((team, index) => {
            team.classList.add("team-entry");
            team.style.setProperty('--delay', `${index * 0.1}s`);
          });
        });
      }
    }
  }
};

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  hooks: Hooks,
  params: {_csrf_token: csrfToken}
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

// Add CSS animations
const style = document.createElement('style');
style.textContent = `
  /* Grid cell entrance animation */
  @keyframes gridCellEnter {
    0% {
      opacity: 0;
      transform: scale(0.9) translateY(10px);
    }
    100% {
      opacity: 1;
      transform: scale(1) translateY(0);
    }
  }

  /* Team entry animation */
  @keyframes teamEnter {
    0% {
      opacity: 0;
      transform: translateX(-20px);
    }
    100% {
      opacity: 1;
      transform: translateX(0);
    }
  }

  /* View transition styles */
  .game-grid {
    transition: opacity 0.3s ease-out;
  }

  .standings-view {
    transition: opacity 0.3s ease-out;
  }

  /* Grid cell animation */
  .grid-cell {
    opacity: 0;
    animation: gridCellEnter 0.4s ease-out forwards;
    animation-delay: var(--delay, 0s);
  }

  /* Team entry animation */
  .team-entry {
    opacity: 0;
    animation: teamEnter 0.4s ease-out forwards;
    animation-delay: var(--delay, 0s);
  }

  /* Hover effects */
  .grid-cell:hover {
    transform: scale(1.02) translateY(-2px);
    transition: transform 0.2s ease-out;
  }

  .team-entry:hover {
    transform: scale(1.01);
    transition: transform 0.2s ease-out;
  }
`;

document.head.appendChild(style);

window.addEventListener("phx:reload_page", () => {
  window.location.reload();
});

