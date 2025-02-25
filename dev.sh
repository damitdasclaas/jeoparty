#!/bin/bash

# Make this script executable with: chmod +x dev.sh

# Function to display help message
show_help() {
  echo "Jeoparty Development Helper"
  echo ""
  echo "Usage: ./dev.sh [COMMAND]"
  echo ""
  echo "Commands:"
  echo "  up              Start the development environment"
  echo "  down            Stop the development environment"
  echo "  restart         Restart the development environment"
  echo "  shell           Open a shell in the web container"
  echo "  mix [args]      Run mix commands in the container"
  echo "  test            Run tests"
  echo "  logs            Show logs from the web container"
  echo "  setup           Set up the development environment (first time setup)"
  echo "  rebuild         Rebuild the web container (use after Dockerfile.dev changes)"
  echo "  help            Show this help message"
  echo ""
}

# Check if Docker is running
docker_running() {
  docker info > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo "Error: Docker is not running. Please start Docker and try again."
    exit 1
  fi
}

# Function to check if a container is running
container_running() {
  local container_name=$1
  docker-compose ps -q $container_name > /dev/null 2>&1
  return $?
}

# Main command handler
case "$1" in
  up)
    docker_running
    echo "Starting development environment..."
    docker-compose up -d
    
    # Check if web container started successfully
    sleep 3
    if ! container_running web; then
      echo "Error: Web container failed to start. Checking logs..."
      docker-compose logs web
      echo ""
      echo "You may need to rebuild the container with: ./dev.sh rebuild"
      exit 1
    fi
    
    echo "Development environment is running at http://localhost:4000"
    ;;
  down)
    docker_running
    echo "Stopping development environment..."
    docker-compose down
    ;;
  restart)
    docker_running
    echo "Restarting development environment..."
    docker-compose down
    docker-compose up -d
    
    # Check if web container started successfully
    sleep 3
    if ! container_running web; then
      echo "Error: Web container failed to start. Checking logs..."
      docker-compose logs web
      echo ""
      echo "You may need to rebuild the container with: ./dev.sh rebuild"
      exit 1
    fi
    
    echo "Development environment is running at http://localhost:4000"
    ;;
  shell)
    docker_running
    if ! container_running web; then
      echo "Error: Web container is not running. Start it with: ./dev.sh up"
      exit 1
    fi
    echo "Opening shell in web container..."
    docker-compose exec web bash
    ;;
  mix)
    docker_running
    if ! container_running web; then
      echo "Error: Web container is not running. Start it with: ./dev.sh up"
      exit 1
    fi
    shift
    docker-compose exec web bash -c "mix $*"
    ;;
  test)
    docker_running
    if ! container_running web; then
      echo "Error: Web container is not running. Start it with: ./dev.sh up"
      exit 1
    fi
    echo "Running tests..."
    docker-compose exec web bash -c "mix test"
    ;;
  logs)
    docker_running
    docker-compose logs -f web
    ;;
  rebuild)
    docker_running
    echo "Rebuilding web container..."
    docker-compose down
    docker-compose build --no-cache web
    docker-compose up -d
    echo "Web container rebuilt and started."
    ;;
  setup)
    docker_running
    echo "Setting up development environment..."
    docker-compose up -d db
    echo "Waiting for database to be ready..."
    sleep 5
    docker-compose build web
    docker-compose up -d web
    
    # Check if web container started successfully
    sleep 3
    if ! container_running web; then
      echo "Error: Web container failed to start. Checking logs..."
      docker-compose logs web
      echo ""
      echo "You may need to rebuild the container with: ./dev.sh rebuild"
      exit 1
    fi
    
    echo "Running database setup..."
    docker-compose exec web bash -c "mix ecto.setup"
    echo "Setup complete! Development environment is running at http://localhost:4000"
    ;;
  help|*)
    show_help
    ;;
esac 