#!/bin/bash
set -euo pipefail

# Environment variables:
#   REMOVE_STATE_DIR: When set to true, also removes the local .vault-dev directory.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REMOVE_STATE_DIR="${REMOVE_STATE_DIR:-true}"

detect_compose_cmd() {
  if command -v podman-compose >/dev/null 2>&1; then
    echo "podman-compose"
    return
  fi

  if command -v podman >/dev/null 2>&1 && podman compose version >/dev/null 2>&1; then
    echo "podman compose"
    return
  fi

  echo "Unable to find podman-compose or the podman compose plugin." >&2
  exit 1
}

COMPOSE_CMD="$(detect_compose_cmd)"

echo "Stopping Vault dev container..."
(cd "${ROOT_DIR}" && ${COMPOSE_CMD} down)

if [[ "${REMOVE_STATE_DIR}" == "true" ]]; then
  rm -rf "${ROOT_DIR}/.vault-dev"
  echo "Removed local state directory .vault-dev/."
fi

echo "Cleanup complete."

