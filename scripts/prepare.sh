#!/usr/bin/env bash

set -e
cd "$(dirname "$0")"/../

TAG=$1

if [ -z "$TAG" ]; then
    echo "Usage: $0 <tag|branch|commit>"
    exit 1
fi

# Check if seanime directory exists
if [ -d "seanime" ]; then
    echo "Seanime directory exists, updating..."
    cd seanime
    git fetch origin
    git checkout "$TAG"
    if git show-ref --verify --quiet "refs/heads/$TAG"; then
        git pull origin "$TAG"
    fi
    cd ..
else
    echo "Cloning Seanime..."
    git clone https://github.com/5rahim/seanime.git
    cd seanime
    git checkout "$TAG"
    cd ..
fi

# Copy the files to the root of the project (excluding .git and Dockerfile if present)
echo "Copying files to root..."
rsync -av --exclude='.git' --exclude='Dockerfile' seanime/ .
