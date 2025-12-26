#!/usr/bin/env bash

set -e
cd "$(dirname "$0")"/../

# Clone the latest version of Seanime
git clone https://github.com/5rahim/seanime.git

# Checkout the specified release tag
cd seanime
git checkout $1
cd ..

# Move the files to the root of the project
mv seanime/* .
cp .docker/.dockerignore .