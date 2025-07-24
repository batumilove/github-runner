#!/bin/bash

echo "GitHub Actions Runner - Ephemeral Mode"
echo "Organization: ${GITHUB_ORG}"

# Function to fetch token using PAT
fetch_token_with_pat() {
    if [ -n "${GITHUB_PAT}" ]; then
        echo "Fetching registration token using PAT..." >&2
        echo "Organization: ${GITHUB_ORG}" >&2
        echo "API URL: https://api.github.com/orgs/${GITHUB_ORG}/actions/runners/registration-token" >&2
        
        # First check if curl and jq are available
        if \! command -v curl >/dev/null 2>&1; then
            echo "ERROR: curl is not installed"
            return 1
        fi
        
        if \! command -v jq >/dev/null 2>&1; then
            echo "ERROR: jq is not installed"
            return 1
        fi
        
        response=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X POST \
            -H "Authorization: token ${GITHUB_PAT}" \
            -H "Accept: application/vnd.github+json" \
            "https://api.github.com/orgs/${GITHUB_ORG}/actions/runners/registration-token")
        
        http_status=$(echo "$response"  < /dev/null |  grep "HTTP_STATUS:" | cut -d: -f2)
        body=$(echo "$response" | sed '$d')
        
        echo "HTTP Status: $http_status" >&2
        echo "Response body length: ${#body}" >&2
        
        if [ "$http_status" != "201" ]; then
            echo "Failed to get token. HTTP status: $http_status" >&2
            echo "Response body: $body" >&2
            return 1
        fi
        
        # Extract token
        token=$(echo "$body" | jq -r '.token' 2>/dev/null)
        if [ "$token" != "null" ] && [ -n "$token" ]; then
            echo "Successfully extracted token" >&2
            echo "$token"
        else
            echo "Failed to extract token from response" >&2
            echo "Response was: $body" >&2
            return 1
        fi
    fi
}

# Main loop
while true; do
    if [ -z "${RUNNER_TOKEN}" ] && [ -n "${GITHUB_PAT}" ]; then
        echo "Fetching token with PAT..."
        RUNNER_TOKEN=$(fetch_token_with_pat)
        if [ -z "${RUNNER_TOKEN}" ]; then
            echo "Failed to fetch token. Check PAT permissions (needs admin:org)"
            sleep 60
            continue
        fi
    elif [ -z "${RUNNER_TOKEN}" ]; then
        echo "ERROR: No RUNNER_TOKEN or GITHUB_PAT provided\!"
        sleep 60
        continue
    fi
    
    echo "Configuring runner..."
    ./config.sh --unattended --ephemeral --url "${ORG_URL}" \
        --token "${RUNNER_TOKEN}" --name "${RUNNER_NAME}" \
        --labels "${RUNNER_LABELS}" --work "${RUNNER_WORKDIR}" --replace
    
    echo "Starting runner..."
    ./run.sh
    
    echo "Runner exited. Refreshing token for next job..."
    unset RUNNER_TOKEN
    sleep 5
done
