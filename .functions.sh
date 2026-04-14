#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -euo pipefail

# Function to get the project name
get_project() {
  local project_name=$(basename "${PWD}")
  if [[ -z "$project_name" ]]; then
    echo "Error: Failed to determine project name."
    exit 1
  fi
  echo "$project_name"
}

# Function to build arguments for docker compose
build_compose_args() {
  local args=()
  # You can add more arguments based on your requirements
  args+=(--build)

  echo "
  echo "
  echo "
  echo "
  echo "Final build arguments: ${args[@]}"
}

# Main script execution starts here
main() {
  local project=$(get_project)
  echo "Building project: $project"

  build_compose_args
  # Additional commands can be added here for further processing
}

main "$@"