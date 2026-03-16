#!/bin/bash
set -euo pipefail

# Environment variables:
#   VAULT_ADDR: Vault HTTP address. Defaults to http://127.0.0.1:8200.
#   VAULT_TOKEN: Vault admin token. Defaults to root.
#   DEMO_USERNAME: Demo user created for userpass auth. Defaults to demo.
#   DEMO_PASSWORD: Demo user password. Defaults to demo-password.
#   TRAINING_SECRETS_PATH: KV v2 path for demo secrets. Defaults to training.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VAULT_ADDR="${VAULT_ADDR:-http://127.0.0.1:8200}"
VAULT_TOKEN="${VAULT_TOKEN:-root}"
DEMO_USERNAME="${DEMO_USERNAME:-demo}"
DEMO_PASSWORD="${DEMO_PASSWORD:-demo-password}"
TRAINING_SECRETS_PATH="${TRAINING_SECRETS_PATH:-training}"
STATE_DIR="${ROOT_DIR}/.vault-dev"
ENV_FILE="${STATE_DIR}/env"

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

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

vault_health_ready() {
  local status
  status="$(curl --silent --output /dev/null --write-out '%{http_code}' "${VAULT_ADDR}/v1/sys/health" || true)"
  [[ "$status" == "200" ]]
}

wait_for_vault() {
  local attempt
  for attempt in $(seq 1 30); do
    if vault_health_ready; then
      echo "Vault is responding at ${VAULT_ADDR}."
      return
    fi

    echo "Waiting for Vault to become ready (${attempt}/30)..."
    sleep 2
  done

  echo "Vault did not become ready in time." >&2
  exit 1
}

require_command podman
require_command curl

COMPOSE_CMD="$(detect_compose_cmd)"

echo "Using compose command: ${COMPOSE_CMD}"
echo "Starting Vault dev container..."
(cd "${ROOT_DIR}" && ${COMPOSE_CMD} up -d)

wait_for_vault

VAULT_ADDR="${VAULT_ADDR}" \
VAULT_TOKEN="${VAULT_TOKEN}" \
DEMO_USERNAME="${DEMO_USERNAME}" \
DEMO_PASSWORD="${DEMO_PASSWORD}" \
TRAINING_SECRETS_PATH="${TRAINING_SECRETS_PATH}" \
  "${ROOT_DIR}/scripts/init-vault.sh"

mkdir -p "${STATE_DIR}"
cat > "${ENV_FILE}" <<EOF
export VAULT_ADDR="${VAULT_ADDR}"
export VAULT_TOKEN="${VAULT_TOKEN}"
export DEMO_VAULT_USER="${DEMO_USERNAME}"
export DEMO_VAULT_PASSWORD="${DEMO_PASSWORD}"
export TRAINING_SECRETS_PATH="${TRAINING_SECRETS_PATH}"
EOF

echo
echo "Vault lab is ready."
echo "Source ${ENV_FILE} to load the demo environment variables."
echo "Root token: ${VAULT_TOKEN}"
echo "Demo username: ${DEMO_USERNAME}"
echo "Demo password: ${DEMO_PASSWORD}"

