#!/bin/bash
set -euo pipefail

# Environment variables:
#   VAULT_ADDR: Vault HTTP address. Defaults to http://127.0.0.1:8200.
#   VAULT_TOKEN: Vault token with admin privileges. Defaults to root.
#   TRAINING_SECRETS_PATH: KV v2 path for demo secrets. Defaults to training.
#   DEMO_USERNAME: Demo user created for userpass auth. Defaults to demo.
#   DEMO_PASSWORD: Demo user password. Defaults to demo-password.

VAULT_ADDR="${VAULT_ADDR:-http://127.0.0.1:8200}"
VAULT_TOKEN="${VAULT_TOKEN:-root}"
TRAINING_SECRETS_PATH="${TRAINING_SECRETS_PATH:-training}"
DEMO_USERNAME="${DEMO_USERNAME:-demo}"
DEMO_PASSWORD="${DEMO_PASSWORD:-demo-password}"

api() {
  local method="$1"
  local path="$2"
  local data="${3:-}"

  if [[ -n "$data" ]]; then
    curl --silent --show-error --fail \
      --request "$method" \
      --header "X-Vault-Token: ${VAULT_TOKEN}" \
      --header "Content-Type: application/json" \
      --data "$data" \
      "${VAULT_ADDR}/v1/${path}"
  else
    curl --silent --show-error --fail \
      --request "$method" \
      --header "X-Vault-Token: ${VAULT_TOKEN}" \
      "${VAULT_ADDR}/v1/${path}"
  fi
}

echo "Configuring Vault dev instance at ${VAULT_ADDR}..."

mounts_json="$(api GET sys/mounts)"
if [[ "$mounts_json" != *"\"${TRAINING_SECRETS_PATH}/\""* ]]; then
  echo "Enabling KV v2 secrets engine at ${TRAINING_SECRETS_PATH}/..."
  api POST "sys/mounts/${TRAINING_SECRETS_PATH}" \
    "{\"type\":\"kv\",\"options\":{\"version\":\"2\"}}" >/dev/null
else
  echo "KV v2 secrets engine already enabled at ${TRAINING_SECRETS_PATH}/."
fi

echo "Writing demo secret to ${TRAINING_SECRETS_PATH}/app..."
api POST "${TRAINING_SECRETS_PATH}/data/app" \
  "{\"data\":{\"username\":\"demo-app\",\"password\":\"change-me\",\"note\":\"safe-for-local-lab-only\"}}" >/dev/null

auth_json="$(api GET sys/auth)"
if [[ "$auth_json" != *"\"userpass/\""* ]]; then
  echo "Enabling userpass auth method..."
  api POST "sys/auth/userpass" "{\"type\":\"userpass\"}" >/dev/null
else
  echo "userpass auth method already enabled."
fi

echo "Writing demo-read policy..."
policy_payload="$(cat <<EOF
{"policy":"path \"${TRAINING_SECRETS_PATH}/data/*\" { capabilities = [\"read\", \"list\"] }\npath \"${TRAINING_SECRETS_PATH}/metadata/*\" { capabilities = [\"read\", \"list\"] }"}
EOF
)"
api PUT "sys/policies/acl/demo-read" "${policy_payload}" >/dev/null

echo "Creating or updating demo user ${DEMO_USERNAME}..."
api POST "auth/userpass/users/${DEMO_USERNAME}" \
  "{\"password\":\"${DEMO_PASSWORD}\",\"token_policies\":\"demo-read\"}" >/dev/null

echo "Vault initialization complete."
