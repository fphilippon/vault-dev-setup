# vault-dev-setup

Local HashiCorp Vault dev lab for macOS using Podman. This repo is meant to give a repeatable environment for self-training, client demos, and quick feature walkthroughs without needing a production-grade Vault deployment.

## What this gives you

- A local Vault container running in dev mode on `http://localhost:8200`
- A one-command setup flow for starting Vault and seeding demo data
- An idempotent initialization script that enables a training KV engine and demo auth
- A cleanup script to tear down the lab quickly between practice sessions or demos

## Prerequisites

Install these on your Mac before using the lab:

- `podman`
- `podman-compose` or the `podman compose` plugin
- `curl`
- `bash`

### Install Podman and Podman Compose on macOS

If you use Homebrew, install both packages with:

```bash
brew install podman podman-compose
```

Then initialize and start the local Podman machine:

```bash
podman machine init
podman machine start
```

Confirm the tools are available:

```bash
podman --version
podman-compose --version
```

## Repository layout

```text
.
├── podman-compose.yml
├── scripts
│   ├── cleanup.sh
│   ├── init-vault.sh
│   └── setup.sh
└── README.md
```

## Quick start

Start the full lab:

```bash
./scripts/setup.sh
```

Load the generated environment variables into your shell:

```bash
source .vault-dev/env
```

Verify Vault is healthy:

```bash
curl --silent "$VAULT_ADDR/v1/sys/health"
```

## Common commands

Start Vault in dev mode without initialization:

```bash
podman-compose up -d
```

Run the initialization step again:

```bash
./scripts/init-vault.sh
```

Check container status:

```bash
podman-compose ps
```

Follow Vault logs:

```bash
podman-compose logs -f vault
```

Stop the lab:

```bash
podman-compose down
```

Stop and remove local state:

```bash
./scripts/cleanup.sh
```

## What setup configures

The setup flow performs these actions:

- starts a Vault dev server with a fixed root token of `root`
- enables a KV v2 secrets engine at `training/`
- writes a demo secret to `training/app`
- enables the `userpass` auth method
- creates a `demo-read` policy with read access to the training secrets
- creates a demo user named `demo` with password `demo-password`
- writes a local `.vault-dev/env` file for quick shell exports

## Demo workflow

After running `source .vault-dev/env`, you can exercise the seeded data with API calls:

Read the seeded secret with the root token:

```bash
curl --silent \
  --header "X-Vault-Token: $VAULT_TOKEN" \
  "$VAULT_ADDR/v1/training/data/app"
```

Log in as the demo user:

```bash
curl --silent \
  --request POST \
  --data '{"password":"demo-password"}' \
  "$VAULT_ADDR/v1/auth/userpass/login/demo"
```

## Customization

You can override defaults with environment variables when running the scripts:

```bash
VAULT_ADDR=http://127.0.0.1:8200 \
VAULT_TOKEN=root \
DEMO_USERNAME=demo \
DEMO_PASSWORD=demo-password \
TRAINING_SECRETS_PATH=training \
./scripts/setup.sh
```

## Notes for training and demos

- This environment uses Vault dev mode, so it is intentionally stateless and not production-safe.
- Do not commit real tokens, credentials, or customer data into this repository.
- The defaults are optimized for speed and repeatability, not security hardening.
- If you change the setup flow, update the scripts and this README together.
