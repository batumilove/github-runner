#!/bin/bash
set -e

echo "GitHub Actions Runner - Ephemeral Mode"
echo "Organization: ${GITHUB_ORG}"
echo "Runner Name: ${RUNNER_NAME}"
echo "Labels: ${RUNNER_LABELS}"

# Function to fetch token using PAT
fetch_token_with_pat() {
    if [ -n "${GITHUB_PAT}" ]; then
        echo "Fetching registration token using PAT..."
        curl -s -X POST \
            -H "Authorization: token ${GITHUB_PAT}" \
            -H "Accept: application/vnd.github+json" \
            "https://api.github.com/orgs/${GITHUB_ORG}/actions/runners/registration-token" | \
            jq -r '.token'
    fi
}

# Main loop for ephemeral runner
while true; do
    # Try to use provided token first
    if [ -z "${RUNNER_TOKEN}" ] && [ -n "${GITHUB_PAT}" ]; then
        echo "No RUNNER_TOKEN provided, fetching using PAT..."
        RUNNER_TOKEN=$(fetch_token_with_pat)
        if [ -z "${RUNNER_TOKEN}" ]; then
            echo "Failed to fetch token with PAT. Check your PAT permissions (needs admin:org scope)."
            echo "Retrying in 60 seconds..."
            sleep 60
            continue
        fi
        export RUNNER_TOKEN
    elif [ -z "${RUNNER_TOKEN}" ]; then
        echo "ERROR: No RUNNER_TOKEN or GITHUB_PAT provided!"
        echo "Please set one of these environment variables:"
        echo "  - GITHUB_PAT: Personal Access Token with admin:org scope"
        echo "  - RUNNER_TOKEN: Registration token from GitHub"
        echo "Retrying in 60 seconds..."
        sleep 60
        continue
    fi

    echo "Starting runner registration..."
    
    # Configure the runner
    ./config.sh \
        --unattended \
        --ephemeral \
        --url "${ORG_URL}" \
        --token "${RUNNER_TOKEN}" \
        --name "${RUNNER_NAME}" \
        --labels "${RUNNER_LABELS}" \
        --work "${RUNNER_WORKDIR}" \
        --replace
    
    # Run the runner
    echo "Starting runner..."
    ./run.sh
    
    # Runner exited (job completed in ephemeral mode)
    echo "Runner completed job and exited."
    
    # Clear token to force refresh on next iteration
    if [ -n "${GITHUB_PAT}" ]; then
        echo "Refreshing token for next job..."
        unset RUNNER_TOKEN
    else
        echo "No PAT configured. Runner will exit."
        echo "To enable automatic restart, add GITHUB_PAT to your .env file."
        exit 0
    fi
    
    echo "Waiting 5 seconds before next registration..."
    sleep 5
done