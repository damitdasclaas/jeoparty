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
import * as d3 from "d3"

// Define hooks
const Hooks = {
  D3Scoreboard: {
    mounted() {
      // Store the container element
      this.container = this.el;
      this.initScoreboard();
      this.updateScoreboard();

      // Handle LiveView updates
      this.handleEvent("reload_page", () => {
        window.location.reload();
      });

      // Add resize observer to handle container size changes
      this.resizeObserver = new ResizeObserver(() => {
        this.handleResize();
      });
      this.resizeObserver.observe(this.container);
    },
    updated() {
      // Ensure SVG exists
      if (!this.svg || this.svg.empty()) {
        this.initScoreboard();
      }

      // Only update if teams data has changed
      const newTeams = JSON.parse(this.el.dataset.teams);
      const currentTeams = this.lastTeams;
      
      if (!currentTeams || JSON.stringify(newTeams) !== JSON.stringify(currentTeams)) {
        this.lastTeams = newTeams;
        this.updateScoreboard();
      }
    },
    destroyed() {
      // Clean up when the element is removed
      if (this.resizeObserver) {
        this.resizeObserver.disconnect();
      }
      if (this.svg) {
        this.svg.remove();
      }
    },
    handleResize() {
      if (!this.svg || this.svg.empty()) return;

      const width = this.container.clientWidth;
      this.svg.attr("width", width);
      this.width = width - this.margin.left - this.margin.right;
      this.updateScoreboard();
    },
    initScoreboard() {
      // Store margin for reuse
      this.margin = { top: 20, right: 20, bottom: 20, left: 20 };

      // Remove any existing SVG first
      d3.select(this.container).selectAll("svg").remove();

      const width = this.container.clientWidth;
      const height = 500;

      // Create SVG
      this.svg = d3.select(this.container)
        .append("svg")
        .attr("width", width)
        .attr("height", height)
        .attr("class", "overflow-visible");

      // Create container for bars
      this.chartGroup = this.svg
        .append("g")
        .attr("class", "chart-group")
        .attr("transform", `translate(${this.margin.left}, ${this.margin.top})`);

      // Store dimensions
      this.width = width - this.margin.left - this.margin.right;
      this.height = height - this.margin.top - this.margin.bottom;

      // Store initial teams data
      this.lastTeams = JSON.parse(this.el.dataset.teams);
    },
    updateScoreboard() {
      // Safety check
      if (!this.svg || this.svg.empty()) {
        this.initScoreboard();
      }

      const teams = JSON.parse(this.el.dataset.teams);
      const barHeight = 80;
      const barPadding = 15;
      const cornerRadius = 12;

      // Update SVG height based on number of teams
      const height = Math.max(500, (barHeight + barPadding) * teams.length + 40);
      this.svg.attr("height", height);
      this.height = height - this.margin.top - this.margin.bottom;

      // Create scales
      const xScale = d3.scaleLinear()
        .domain([0, Math.max(d3.max(teams, d => Math.abs(d.score)), 100)])
        .range([0, this.width - 300]);

      const yScale = d3.scaleBand()
        .domain(teams.map(d => d.id))
        .range([0, this.height])
        .padding(0.15);

      // Color scale for rank
      const colorScale = d3.scaleOrdinal()
        .domain([1, 2, 3])
        .range([
          "url(#gold-gradient)",
          "url(#silver-gradient)",
          "url(#bronze-gradient)"
        ])
        .unknown("url(#blue-gradient)");

      // Create gradients
      const defs = this.svg.append("defs");
      
      // Gold gradient
      const goldGradient = defs.append("linearGradient")
        .attr("id", "gold-gradient")
        .attr("x1", "0%")
        .attr("y1", "0%")
        .attr("x2", "100%")
        .attr("y2", "0%");
      goldGradient.append("stop")
        .attr("offset", "0%")
        .attr("stop-color", "#fbbf24")
        .attr("stop-opacity", 1);
      goldGradient.append("stop")
        .attr("offset", "100%")
        .attr("stop-color", "#f59e0b")
        .attr("stop-opacity", 1);

      // Silver gradient
      const silverGradient = defs.append("linearGradient")
        .attr("id", "silver-gradient")
        .attr("x1", "0%")
        .attr("y1", "0%")
        .attr("x2", "100%")
        .attr("y2", "0%");
      silverGradient.append("stop")
        .attr("offset", "0%")
        .attr("stop-color", "#9ca3af")
        .attr("stop-opacity", 1);
      silverGradient.append("stop")
        .attr("offset", "100%")
        .attr("stop-color", "#6b7280")
        .attr("stop-opacity", 1);

      // Bronze gradient
      const bronzeGradient = defs.append("linearGradient")
        .attr("id", "bronze-gradient")
        .attr("x1", "0%")
        .attr("y1", "0%")
        .attr("x2", "100%")
        .attr("y2", "0%");
      bronzeGradient.append("stop")
        .attr("offset", "0%")
        .attr("stop-color", "#d97706")
        .attr("stop-opacity", 1);
      bronzeGradient.append("stop")
        .attr("offset", "100%")
        .attr("stop-color", "#b45309")
        .attr("stop-opacity", 1);

      // Blue gradient
      const blueGradient = defs.append("linearGradient")
        .attr("id", "blue-gradient")
        .attr("x1", "0%")
        .attr("y1", "0%")
        .attr("x2", "100%")
        .attr("y2", "0%");
      blueGradient.append("stop")
        .attr("offset", "0%")
        .attr("stop-color", "#3b82f6")
        .attr("stop-opacity", 1);
      blueGradient.append("stop")
        .attr("offset", "100%")
        .attr("stop-color", "#2563eb")
        .attr("stop-opacity", 1);

      // Create bars with animated transitions
      const bars = this.chartGroup.selectAll(".score-bar")
        .data(teams, d => d.id);

      // Remove old bars with transition
      bars.exit()
        .transition()
        .duration(500)
        .style("opacity", 0)
        .remove();

      // Create new bars
      const barsEnter = bars.enter()
        .append("g")
        .attr("class", "score-bar")
        .style("opacity", 0);

      // Update existing bars and new bars
      const barsUpdate = barsEnter.merge(bars);

      // Transition for position and opacity
      barsUpdate.transition()
        .duration(750)
        .style("opacity", 1)
        .attr("transform", d => `translate(0, ${yScale(d.id)})`);

      // Background rect
      barsUpdate.selectAll(".bar-bg")
        .data(d => [d])
        .join(
          enter => enter.append("rect")
            .attr("class", "bar-bg")
            .attr("x", 0)
            .attr("y", 0)
            .attr("width", this.width)
            .attr("height", barHeight)
            .attr("rx", cornerRadius)
            .attr("fill", "rgba(255, 255, 255, 0.03)")
            .attr("stroke", "rgba(255, 255, 255, 0.1)")
            .attr("stroke-width", 2)
            .attr("opacity", 0)
            .transition()
            .duration(750)
            .attr("opacity", 1),
          update => update.transition()
            .duration(750)
            .attr("width", this.width)
        );

      // Score bars with glass effect
      barsUpdate.selectAll(".bar")
        .data(d => [d])
        .join(
          enter => {
            const bar = enter.append("g")
              .attr("class", "bar");

            // Main bar - only for positive scores
            bar.append("rect")
              .attr("class", "bar-fill")
              .attr("x", 250)
              .attr("y", barPadding)
              .attr("height", barHeight - barPadding * 2)
              .attr("rx", cornerRadius)
              .attr("width", 0)
              .style("fill", d => colorScale(d.rank))
              .style("filter", "url(#glow)")
              .style("opacity", d => d.score >= 0 ? 1 : 0);

            // Shine effect - only for positive scores
            bar.append("rect")
              .attr("class", "bar-shine")
              .attr("x", 250)
              .attr("y", barPadding)
              .attr("height", (barHeight - barPadding * 2) * 0.5)
              .attr("rx", cornerRadius)
              .attr("width", 0)
              .style("fill", "rgba(255, 255, 255, 0.1)")
              .style("opacity", d => d.score >= 0 ? 1 : 0);

            return bar;
          },
          update => {
            update.select(".bar-fill")
              .transition()
              .duration(750)
              .style("fill", d => colorScale(d.rank))
              .style("opacity", d => d.score >= 0 ? 1 : 0)
              .attr("width", d => d.score >= 0 ? xScale(d.score) : 0);

            update.select(".bar-shine")
              .transition()
              .duration(750)
              .style("opacity", d => d.score >= 0 ? 1 : 0)
              .attr("width", d => d.score >= 0 ? xScale(d.score) : 0);

            return update;
          }
        );

      // Add glow filter
      const filter = defs.append("filter")
        .attr("id", "glow");

      filter.append("feGaussianBlur")
        .attr("stdDeviation", "4")
        .attr("result", "coloredBlur");

      const feMerge = filter.append("feMerge");
      feMerge.append("feMergeNode")
        .attr("in", "coloredBlur");
      feMerge.append("feMergeNode")
        .attr("in", "SourceGraphic");

      // Rank circles with glass effect
      barsUpdate.selectAll(".rank")
        .data(d => [d])
        .join(
          enter => {
            const rankGroup = enter.append("g")
              .attr("class", "rank")
              .attr("transform", d => `translate(30, ${barHeight/2})`);
            
            // Circle background
            rankGroup.append("circle")
              .attr("r", 26)
              .attr("fill", d => colorScale(d.rank))
              .style("filter", "url(#glow)");
            
            // Shine effect
            rankGroup.append("circle")
              .attr("r", 26)
              .attr("fill", "rgba(255, 255, 255, 0.1)")
              .attr("clip-path", "circle(26px at 0 -13px)");
            
            rankGroup.append("text")
              .attr("text-anchor", "middle")
              .attr("dy", "0.35em")
              .attr("fill", "white")
              .attr("font-weight", "bold")
              .attr("font-size", "24px")
              .text(d => d.rank);
            
            return rankGroup;
          },
          update => {
            update.select("circle")
              .transition()
              .duration(750)
              .attr("fill", d => colorScale(d.rank));
            
            update.select("text")
              .transition()
              .duration(750)
              .tween("text", function(d) {
                const i = d3.interpolateRound(+this.textContent || 0, d.rank);
                return function(t) {
                  this.textContent = i(t);
                };
              });
            
            return update;
          }
        );

      // Team names
      barsUpdate.selectAll(".team-name")
        .data(d => [d])
        .join(
          enter => enter.append("text")
            .attr("class", "team-name")
            .attr("x", 80)
            .attr("y", barHeight/2)
            .attr("dy", "0.35em")
            .attr("fill", "white")
            .attr("font-size", "32px")
            .attr("font-weight", "600")
            .style("font-family", "'Rubik', sans-serif")
            .style("text-shadow", "0 2px 4px rgba(0,0,0,0.2)")
            .text(d => d.name),
          update => update.text(d => d.name)
        );

      // Score text
      barsUpdate.selectAll(".score")
        .data(d => [d])
        .join(
          enter => enter.append("text")
            .attr("class", "score")
            .attr("x", d => d.score >= 0 ? 260 + xScale(d.score) + 20 : 260)
            .attr("y", barHeight/2)
            .attr("dy", "0.35em")
            .attr("text-anchor", "start")
            .attr("dominant-baseline", "middle")
            .attr("fill", d => d.score >= 0 ? "white" : "#ef4444")
            .attr("font-size", "28px")
            .attr("font-weight", "bold")
            .style("font-family", "'Press Start 2P', cursive")
            .style("letter-spacing", "-0.05em")
            .style("text-shadow", "0 2px 4px rgba(0,0,0,0.2)")
            .text(d => `$${d.score.toLocaleString()}`),
          update => update
            .transition()
            .duration(750)
            .attr("x", d => d.score >= 0 ? 260 + xScale(d.score) + 20 : 260)
            .attr("fill", d => d.score >= 0 ? "white" : "#ef4444")
            .tween("text", function(d) {
              const i = d3.interpolate(this._current || d.score, d.score);
              this._current = d.score;
              return function(t) {
                d3.select(this).text(`$${Math.round(i(t)).toLocaleString()}`);
              };
            })
        );
    }
  },
  AnimateScore: {
    mounted() {
      this.handleScoreChange();
      this.lastScore = parseInt(this.el.dataset.score);
      this.lastPosition = this.el.getBoundingClientRect().top;
      this.lastRank = this.getRank();
    },
    updated() {
      this.handleScoreChange();
      this.handlePositionChange();
    },
    getRank() {
      // Get rank from the parent's data attribute or compute it from position
      return parseInt(this.el.closest('[data-rank]')?.dataset.rank) || 
             Math.floor(this.el.getBoundingClientRect().top / 100);
    },
    handleScoreChange() {
      const newScore = parseInt(this.el.dataset.score);
      
      if (this.lastScore !== undefined && newScore !== this.lastScore) {
        // Remove any existing animation classes
        this.el.classList.remove('score-change', 'score-decrease');
        
        // Force a reflow to ensure the animation triggers again
        void this.el.offsetWidth;
        
        // Add appropriate animation class based on score change
        if (newScore > this.lastScore) {
          this.el.classList.add('score-change');
        } else if (newScore < this.lastScore) {
          this.el.classList.add('score-decrease');
        }
      }
      
      this.lastScore = newScore;
    },
    handlePositionChange() {
      const newPosition = this.el.getBoundingClientRect().top;
      const newRank = this.getRank();
      
      if (this.lastPosition !== undefined && 
          this.lastRank !== undefined && 
          (newPosition !== this.lastPosition || newRank !== this.lastRank)) {
        
        // Remove existing animation classes
        this.el.classList.remove('position-changed');
        
        // Force a reflow
        void this.el.offsetWidth;
        
        // Add animation classes
        this.el.classList.add('position-transition', 'position-changed');
        
        // Remove the animation class after it completes
        setTimeout(() => {
          this.el.classList.remove('position-changed');
        }, 600);
      }
      
      this.lastPosition = newPosition;
      this.lastRank = newRank;
    }
  },
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
        const teams = standings.querySelectorAll("#leaderboard > div");
        const totalTeams = teams.length;
        
        // Reset all animations first
        teams.forEach(team => {
          team.classList.remove('animate');
          team.classList.add('team-entry');
        });
        
        // Force a reflow
        void standings.offsetWidth;
        
        // Start animations with staggered delays
        requestAnimationFrame(() => {
          teams.forEach((team, index) => {
            team.style.setProperty('--delay', `${index * 0.1}s`);
            team.classList.add('animate');
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
      transform: translateY(-100px);
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
    transition: all 0.2s ease-out;
  }

  /* Ensure all transform properties transition smoothly */
  #leaderboard > div {
    transition: all 0.5s ease-out;
  }
`;

document.head.appendChild(style);

window.addEventListener("phx:reload_page", () => {
  window.location.reload();
});

