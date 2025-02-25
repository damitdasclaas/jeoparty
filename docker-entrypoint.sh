#!/bin/bash
set -e

# Ensure PATH includes Elixir and Erlang binaries
export PATH="/usr/local/bin:$PATH"

# Print versions for debugging
echo "Elixir version:"
elixir --version

echo "Mix version:"
mix --version

# Execute the passed command
exec "$@" 