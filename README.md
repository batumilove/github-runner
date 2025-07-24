# GitHub Actions Self-Hosted Runner (Docker)

Ephemeral self-hosted GitHub Actions runner for organizations with full NixOS compatibility.

## Features

- ✅ Ephemeral runners (fresh environment for each job)
- ✅ Automatic token renewal using GitHub PAT
- ✅ Organization-level runner support
- ✅ NixOS Docker compatibility
- ✅ No external script dependencies

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
docker-compose up -d
```

## Using in Workflows

```yaml
runs-on: [self-hosted, docker, linux, org]
```

## Commands

- **Logs:** `docker-compose logs -f`
- **Stop:** `docker-compose down`
- **Restart:** `docker-compose restart`
- **Update:** `docker-compose pull && docker-compose up -d`

## NixOS Compatibility

This runner is fully compatible with NixOS. The script is embedded directly in the `docker-compose.yml` file to avoid file mounting issues that can occur with NixOS Docker installations.

## How It Works

1. **Token Management**: 
   - Uses either a registration token (expires in 1 hour) or a GitHub PAT
   - With PAT, automatically fetches new registration tokens as needed
   - PAT requires `admin:org` scope for organization runners

2. **Ephemeral Mode**:
   - Runner registers, runs one job, then unregisters
   - Ensures clean environment for each workflow run
   - Automatically re-registers for the next job

3. **Embedded Script**:
   - All logic is embedded in `docker-compose.yml`
   - No external script files required
   - Uses `$$` for proper variable escaping in docker-compose

## Troubleshooting

### "Check PAT permissions (needs admin:org)"
Your PAT needs the `admin:org` scope. Create a new token at https://github.com/settings/tokens with this permission.

### Runner not picking up jobs
- Check that your workflow uses the correct labels: `[self-hosted, docker, linux, org]`
- Verify the runner appears in your organization's settings: `https://github.com/organizations/YOUR_ORG/settings/actions/runners`
- Check logs: `docker-compose logs -f`

### NixOS "Is a directory" errors
This should not occur with the current configuration. If it does, ensure you're using the latest `docker-compose.yml` with the embedded script.

## Environment Variables

| Variable | Required | Description | Default |
|----------|----------|-------------|---------|
| `GITHUB_ORG` | Yes | Your GitHub organization name | - |
| `RUNNER_TOKEN` | Yes* | Registration token (if not using PAT) | - |
| `GITHUB_PAT` | Yes* | GitHub Personal Access Token with admin:org scope | - |
| `RUNNER_NAME` | No | Name for the runner | `runner-ephemeral-$$` |
| `RUNNER_LABELS` | No | Labels for the runner | `self-hosted,docker,linux,org` |
| `CONTAINER_NAME` | No | Docker container name suffix | `ephemeral` |

*Either `RUNNER_TOKEN` or `GITHUB_PAT` must be provided