#!/usr/bin/env bash

set -e

# Function to check for required commands
check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo "Error: '$1' is required but not installed."
        exit 1
    fi
}

check_command curl
check_command jq
check_command docker

# Get latest release tag if not provided
if [ -z "$1" ]; then
    echo "Fetching latest release tag from 5rahim/seanime..."
    LATEST_RELEASE=$(curl -s https://api.github.com/repos/5rahim/seanime/releases/latest | jq -r .tag_name)
    echo "Latest release: $LATEST_RELEASE"
else
    LATEST_RELEASE="$1"
    echo "Using provided release: $LATEST_RELEASE"
fi

# Run prepare script
echo "Running prepare script..."
chmod +x ./scripts/prepare.sh
./scripts/prepare.sh "$LATEST_RELEASE"

# Build Default image
echo "Building Default image..."
docker build -t umagistr/seanime:latest --target base .

# Build Rootless image
echo "Building Rootless image..."
docker build -t umagistr/seanime:latest-rootless --target rootless .

# Build HwAccel image
echo "Building HwAccel image..."
docker build -t umagistr/seanime:latest-hwaccel --target hwaccel .

# Build CUDA image
echo "Building CUDA image..."
chmod +x ./scripts/get-cuda-version.sh
CUDA_TAG=$(./scripts/get-cuda-version.sh)
echo "Latest CUDA tag: $CUDA_TAG"

# Backup Dockerfile.cuda
cp Dockerfile.cuda Dockerfile.cuda.bak

# Update Dockerfile.cuda
sed -i "s/CUDA_VERSION_PLACEHOLDER/$CUDA_TAG/g" Dockerfile.cuda

# Build CUDA image
docker build -t umagistr/seanime:latest-cuda -f Dockerfile.cuda .

# Restore Dockerfile.cuda
mv Dockerfile.cuda.bak Dockerfile.cuda

echo "Build complete!"
echo "Images built:"
echo "  - umagistr/seanime:latest"
echo "  - umagistr/seanime:latest-rootless"
echo "  - umagistr/seanime:latest-hwaccel"
echo "  - umagistr/seanime:latest-cuda"
