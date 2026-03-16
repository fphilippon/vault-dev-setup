# Copilot Instructions for vault-dev-setup

## Project Overview

**vault-dev-setup** is a personal lab repository for spinning up a local HashiCorp Vault instance in dev mode using Podman on macOS. The setup uses Podman Compose for container orchestration and includes shell scripts for automated initialization and configuration. This is intended for development, testing, and client demonstrations.

**Target Environment:** macOS + Podman + Vault Dev Mode

## Repository Structure

- `podman-compose.yml` - Main Podman Compose configuration for Vault container
- `/scripts/` - Shell scripts for setup automation
  - `scripts/init-vault.sh` - Initialize Vault with dev mode settings
  - `scripts/setup.sh` - Complete setup automation
  - `scripts/cleanup.sh` - Tear down and clean resources
- `/docs/` - Documentation and setup guides
- `.github/` - GitHub configuration and this file

## Common Commands

```bash
# Start Vault in dev mode
podman-compose up -d

# Initialize and configure Vault
./scripts/setup.sh

# Check Vault status
podman-compose ps

# View Vault logs
podman-compose logs -f vault

# Stop Vault
podman-compose down

# Full cleanup (remove volumes)
./scripts/cleanup.sh
```

## Prerequisites

- **Podman**: Installed and running on macOS (Podman Desktop or CLI)
- **Podman Compose**: Available in $PATH
- **Bash**: For running setup scripts
- **curl**: For API testing (usually pre-installed on macOS)

## Key Conventions

### Podman Specifics (macOS)
- Always use `podman` commands compatible with Podman on macOS (not Docker-specific syntax)
- Reference the Vault HashiCorp image: `docker.io/library/vault` (Podman can pull from Docker Hub)
- Dev mode is the standard for this lab (data not persisted across restarts)
- Vault will be accessible at `http://localhost:8200`

### Shell Scripts
- All scripts must be executable (`chmod +x`) and start with `#!/bin/bash`
- Include error handling and clear output messages
- Document environment variables and expected arguments at the top of each script
- Make scripts idempotent where possible (safe to run multiple times)

### Documentation
- README.md: Quick start guide, basic commands, and prerequisites
- Keep sensitive data (tokens, keys) out of git; add `.env` to .gitignore if needed
- Update this file when conventions change

### Git Practices
- Use clear commit messages (e.g., "Add Vault initialization script", "Update setup instructions")
- Reference use case in commits (e.g., "for client demos" or "dev testing")

## Development Workflow

1. **When adding a new setup step**: Update both the script and README.md simultaneously
2. **When changing Podman Compose config**: Test with `podman-compose up` before committing
3. **When adding scripts**: Make executable, test on macOS, and document in this file and README.md
4. **Before committing**: Verify all commands work on a clean macOS + Podman setup

## Common Tasks

- **Testing a script**: Run `./scripts/your-script.sh` locally, check exit codes and output
- **Adding initialization logic**: Extend `scripts/init-vault.sh` with new Vault configuration
- **Checking container health**: Use `podman-compose logs vault` or `podman ps --format json | jq`
- **Exporting Vault data**: Document how to backup/export state if needed for demos

## Important Notes

- This is a dev/demo lab, so focus on ease of use and reproducibility
- Vault dev mode is stateless; clearly document this for demo users
- Test all changes on macOS with Podman before committing
- Keep setup as automated as possible to minimize manual steps
