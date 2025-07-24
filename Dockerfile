FROM ghcr.io/actions/actions-runner:latest

USER root

# Copy the entrypoint script
COPY --chmod=755 runner-entrypoint.sh /runner-entrypoint.sh

USER runner

# Set it as entrypoint
ENTRYPOINT ["/runner-entrypoint.sh"]