# Jeoparty

To start your Phoenix server:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Docker Development Setup

This project supports development using Docker, which makes it easy to run on any operating system, including Windows.

### Prerequisites

- [Docker](https://www.docker.com/products/docker-desktop/)
- [Docker Compose](https://docs.docker.com/compose/install/) (usually included with Docker Desktop)

### Getting Started with Docker

1. Clone this repository
2. Make the helper script executable (if not already):
   ```
   chmod +x dev.sh
   ```
3. Set up the development environment:
   ```
   ./dev.sh setup
   ```
4. Access the application at [`localhost:4000`](http://localhost:4000)

### Common Development Tasks

The `dev.sh` script provides shortcuts for common development tasks:

- Start the environment: `./dev.sh up`
- Stop the environment: `./dev.sh down`
- Restart the environment: `./dev.sh restart`
- Open a shell in the container: `./dev.sh shell`
- Run mix commands: `./dev.sh mix <command>` (e.g., `./dev.sh mix deps.get`)
- Run tests: `./dev.sh test`
- View logs: `./dev.sh logs`

For a full list of commands, run `./dev.sh help`

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
