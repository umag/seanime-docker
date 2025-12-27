#!/usr/bin/env bash

# Default fallback version
DEFAULT_VERSION="13.0.2-base-ubuntu24.04"

# Fetch tags from Docker Hub
# We look for tags containing "base-ubuntu" to get the base images based on Ubuntu
# This helps filter out devel, runtime, etc.
RESPONSE=$(curl -s "https://registry.hub.docker.com/v2/repositories/nvidia/cuda/tags?page_size=100")

if [ $? -ne 0 ] || [ -z "$RESPONSE" ]; then
    echo "$DEFAULT_VERSION"
    exit 0
fi

# Parse JSON to find the latest version matching our criteria
# We want the highest version number that includes "base-ubuntu"
# Note: jq is available in the GitHub Actions runner environment
LATEST_TAG=$(echo "$RESPONSE" | jq -r '.results[].name' | grep "base-ubuntu" | sort -V | tail -n 1)

if [ -z "$LATEST_TAG" ]; then
    echo "$DEFAULT_VERSION"
else
    echo "$LATEST_TAG"
fi
