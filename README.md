# GitHub Actions Self-Hosted Runner (Docker)

Ephemeral self-hosted GitHub Actions runner for organizations.

## Quick Start

```bash
# 1. Setup
cp .env.template .env
# Edit .env with your org name

# 2. Get token (choose one):
# Option A: Quick token (expires in 1 hour)
gh api -H "Accept: application/vnd.github+json" /orgs/YOUR_ORG/actions/runners/registration-token --jq '.token'
# Add to .env as RUNNER_TOKEN

# Option B: Permanent token (recommended)
# Create PAT at https://github.com/settings/tokens with admin:org scope
# Add to .env as GITHUB_PAT

# 3. Run
# IMPORTANT: Use docker-compose-new.yml for working configuration
docker-compose -f docker-compose-new.yml up -d
```

## Using in Workflows

```yaml
runs-on: [self-hosted, docker, linux, org]
```

## Commands

- **Logs:** `docker-compose -f docker-compose-new.yml logs -f`
- **Stop:** `docker-compose -f docker-compose-new.yml down`
- **Update:** `docker-compose -f docker-compose-new.yml pull && docker-compose -f docker-compose-new.yml up -d`

## Important Note

The original `docker-compose.yml` has syntax errors in the entrypoint script. Please use `docker-compose-new.yml` which uses an external entrypoint script (`runner-entrypoint-new.sh`) for proper functionality.