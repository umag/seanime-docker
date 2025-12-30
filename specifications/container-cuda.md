# CUDA Hardware Acceleration Container Specification

## Overview

The CUDA hardware acceleration Seanime container variant with NVIDIA GPU support
for NVENC/NVDEC video transcoding.

## Image Details

- **Image Tag**: `umagistr/seanime:latest-cuda`
- **Base Image**: `nvidia/cuda:CUDA_VERSION_PLACEHOLDER` (Ubuntu-based)
- **Target**: Built from `Dockerfile.cuda`
- **User**: `seanime` (UID 1001, GID 1001)
- **FFmpeg**: Ubuntu FFmpeg with NVENC support

## Build Process

### Stage 1: Node.js Builder

- **Base**: `node:latest` (buildplatform)
- **Purpose**: Build the web frontend
- **Working Directory**: `/tmp/build`
- **Cache Mounts**:
  - `/root/.npm` - npm package cache
- **Build Steps**:
  1. Copy `package.json` and `package-lock.json`
  2. Install npm dependencies
  3. Copy source files from `./seanime-web`
  4. Run `npm run build`
- **Output**: Frontend built to `/tmp/build/out`

### Stage 2: Go Builder

- **Base**: `golang:latest` (buildplatform)
- **Purpose**: Build the backend binary
- **Working Directory**: `/tmp/build`
- **Cache Mounts**:
  - `/go/pkg/mod` - Go module cache
  - `/root/.cache/go-build` - Go build cache
- **Build Args**:
  - `TARGETOS` - Target OS
  - `TARGETARCH` - Target architecture
- **Build Steps**:
  1. Copy `go.mod` and `go.sum`
  2. Download Go modules
  3. Copy source code
  4. Copy frontend output from node-builder
  5. Build binary with:
     - CGO disabled
     - Trimmed path
     - Stripped symbols (`-ldflags="-s -w"`)
- **Output**: Binary at `/tmp/build/seanime`

### Stage 3: Final Image (CUDA Base)

- **Base**: `nvidia/cuda:CUDA_VERSION_PLACEHOLDER` (Ubuntu)
  - Note: CUDA_VERSION_PLACEHOLDER is replaced during build
- **User Creation**:
  - Group: `seanime` (GID 1001)
  - User: `seanime` (UID 1001)
  - Home directory: `/home/seanime`
  - Shell: `/bin/bash`
  - Additional group: `video` (for GPU access)
- **Installed Packages**:
  - `ca-certificates` - SSL/TLS certificates
  - `tzdata` - Timezone data
  - `ffmpeg` - FFmpeg from Ubuntu repositories (with NVENC support)
  - `curl` - HTTP client (for healthcheck)
- **Package Cleanup**: APT lists removed to reduce image size

## Runtime Configuration

### Binary Location

- Path: `/app/seanime`
- Permissions: Executable
- Owner: `seanime:seanime` (1001:1001)

### Working Directory

- `/app`
- Owner: `seanime:seanime`

### Exposed Ports

- `43211` - Web interface and API

### Volumes

Default mount points (from examples):

- `/home/seanime/.config/Seanime` - Application configuration
- `/anime` - Anime library directory
- `/downloads` - Downloads directory

**Important**: All mounted volumes should have appropriate permissions for UID
1001 / GID 1001.

### NVIDIA Runtime Configuration

**Option 1: Runtime (Recommended)**

```yaml
runtime: nvidia
environment:
  - NVIDIA_VISIBLE_DEVICES=all # or specific GPU: '0', '1', etc.
  - NVIDIA_DRIVER_CAPABILITIES=all
```

**Option 2: Deploy Resources**

```yaml
deploy:
  resources:
    reservations:
      devices:
        - driver: nvidia
          count: 1 # or 'all'
          capabilities: [gpu]
```

### Health Check

- **Interval**: 30 seconds
- **Timeout**: 10 seconds
- **Start Period**: 5 seconds
- **Retries**: 3
- **Command**: `curl -f http://localhost:43211 || exit 1`

### Environment Variables

**Required for GPU access**:

- `NVIDIA_VISIBLE_DEVICES` - Which GPUs to use (default: `all`)
  - `all` - All available GPUs
  - `0` - First GPU only
  - `0,1` - First and second GPUs
  - `<GPU-UUID>` - Specific GPU by UUID
- `NVIDIA_DRIVER_CAPABILITIES` - Driver capabilities to enable
  - `all` - All capabilities (recommended)
  - `compute,video,utility` - Specific capabilities

### Entrypoint/Command

- **USER**: `1001`
- **CMD**: `["/app/seanime"]`

## NVIDIA GPU Support

### Hardware Requirements

- NVIDIA GPU with compute capability 3.0 or higher
- NVIDIA drivers installed on host system (version 418.81.07 or newer)
- NVIDIA Container Toolkit installed on host

### NVENC/NVDEC Features

- **NVENC** - Hardware video encoding
  - H.264 encoding
  - H.265/HEVC encoding (Maxwell and newer)
  - AV1 encoding (Ada Lovelace/RTX 40 series)
- **NVDEC** - Hardware video decoding
  - H.264 decoding
  - H.265/HEVC decoding
  - VP8/VP9 decoding
  - AV1 decoding (Ampere/RTX 30 series and newer)

### Supported GPU Generations

- **Maxwell** (GTX 900 series, GTX 10 series): H.264/H.265 NVENC
- **Pascal** (GTX 10 series, Titan X): Improved NVENC, better quality
- **Turing** (RTX 20 series, GTX 16 series): Enhanced NVENC, B-frames
- **Ampere** (RTX 30 series): AV1 decode, improved quality
- **Ada Lovelace** (RTX 40 series): AV1 encode, enhanced performance

## Security Considerations

### User & Permissions

- Runs as **non-root** user `seanime` (UID 1001, GID 1001)
- File ownership: `seanime:seanime` (1001:1001)
- Member of `video` group for GPU access
- ✅ **Security Benefit**: Reduced attack surface with privilege separation

### GPU Access

- Requires NVIDIA Container Runtime
- Direct GPU access via CUDA runtime
- Risk: Direct hardware access, mitigated by non-root user
- GPU resources shared with other containers if multiple containers use same GPU

### Capabilities

- No special Linux capabilities required
- NVIDIA runtime handles GPU device access
- Limited to non-root user permissions

## Use Cases

- NVIDIA GPU-accelerated video transcoding
- High-performance video encoding/decoding
- Systems with NVIDIA discrete or professional GPUs
- Maximizing transcoding throughput
- Reducing CPU load for video operations
- Production deployments with NVIDIA hardware

## Platform Support

- **Architectures**: amd64 (primary), arm64 (NVIDIA Jetson)
- **OS**: Linux
- **GPU**: NVIDIA GPUs with compute capability 3.0+
- **CUDA**: Version determined by base image placeholder

## Dependencies

- Docker Engine with NVIDIA Container Toolkit
- NVIDIA GPU with driver version 418.81.07+
- NVIDIA Container Runtime (`nvidia-docker2` or Docker with `nvidia` runtime)
- Network access to AniList API
- Optional: Torrent clients for download integration
- Host filesystem permissions for UID 1001

## Host System Setup

### Install NVIDIA Container Toolkit

**Ubuntu/Debian**:

```bash
# Add NVIDIA package repository
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | \
  sudo tee /etc/apt/sources.list.d/nvidia-docker.list

# Install nvidia-docker2
sudo apt-get update
sudo apt-get install -y nvidia-docker2

# Restart Docker
sudo systemctl restart docker
```

**Red Hat/CentOS**:

```bash
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.repo | \
  sudo tee /etc/yum.repos.d/nvidia-docker.repo

sudo yum install -y nvidia-docker2
sudo systemctl restart docker
```

### Verify Installation

```bash
# Test NVIDIA runtime
docker run --rm --runtime=nvidia nvidia/cuda:11.0-base nvidia-smi
```

## Example Deployment

### Docker Compose (Option 1: Runtime)

```yaml
services:
  seanime:
    image: umagistr/seanime:latest-cuda
    container_name: seanime
    runtime: nvidia
    group_add:
      - video
    environment:
      - NVIDIA_VISIBLE_DEVICES=all
      - NVIDIA_DRIVER_CAPABILITIES=all
    ports:
      - "3211:43211"
    volumes:
      - ./seanime-config:/home/seanime/.config/Seanime
      - ./anime:/anime
      - ./downloads:/downloads
    restart: unless-stopped
```

### Docker Compose (Option 2: Deploy)

```yaml
services:
  seanime:
    image: umagistr/seanime:latest-cuda
    container_name: seanime
    group_add:
      - video
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]
    ports:
      - "3211:43211"
    volumes:
      - ./seanime-config:/home/seanime/.config/Seanime
      - ./anime:/anime
      - ./downloads:/downloads
    restart: unless-stopped
```

### Docker Run

```bash
docker run -d \
  --name seanime \
  --runtime=nvidia \
  --group-add video \
  -e NVIDIA_VISIBLE_DEVICES=all \
  -e NVIDIA_DRIVER_CAPABILITIES=all \
  -p 3211:43211 \
  -v ./seanime-config:/home/seanime/.config/Seanime \
  -v ./anime:/anime \
  -v ./downloads:/downloads \
  --restart unless-stopped \
  umagistr/seanime:latest-cuda
```

## Verification

### Check GPU Access

```bash
# Verify NVIDIA runtime
docker exec seanime nvidia-smi

# Should display GPU information
```

### Test FFmpeg NVENC

```bash
# Check available NVENC encoders
docker exec seanime ffmpeg -encoders | grep nvenc

# Expected output includes:
# h264_nvenc, hevc_nvenc, etc.

# Check hardware acceleration methods
docker exec seanime ffmpeg -hwaccels

# Should list 'cuda'
```

### Monitor GPU Usage

```bash
# Watch GPU utilization during transcoding
watch -n 1 nvidia-smi
```

## Troubleshooting

### GPU Not Detected

1. Verify NVIDIA Container Toolkit installation:
   ```bash
   docker run --rm --runtime=nvidia nvidia/cuda:11.0-base nvidia-smi
   ```

2. Check Docker daemon configuration (`/etc/docker/daemon.json`):
   ```json
   {
     "runtimes": {
       "nvidia": {
         "path": "nvidia-container-runtime",
         "runtimeArgs": []
       }
     }
   }
   ```

3. Restart Docker daemon:
   ```bash
   sudo systemctl restart docker
   ```

### NVENC Not Available

1. Verify GPU supports NVENC:
   - Check NVIDIA GPU support matrix
   - Consumer GPUs may have concurrent encoding session limits

2. Check driver version:
   ```bash
   nvidia-smi
   # Driver version should be 418.81.07 or newer
   ```

### Permission Issues

If you encounter permission errors with volumes:

```bash
# Fix volume ownership
sudo chown -R 1001:1001 ./seanime-config ./anime ./downloads
```

If you encounter GPU access issues, ensure your user is in the `video` group:

```bash
# Add user to video group on host
sudo usermod -aG video $(whoami)
# Log out and back in, or reboot for changes to take effect
```

### Container Cannot Start

1. Check runtime specification in compose file
2. Verify NVIDIA runtime is available: `docker info | grep nvidia`
3. Check container logs: `docker logs seanime`

## Performance Considerations

- NVENC provides significantly faster encoding than CPU
- Quality may differ from x264/x265 software encoding
- Consumer GPUs may have concurrent session limits (2-3 streams)
- Professional GPUs (Quadro, Tesla) have no session limits
- First transcode may have GPU initialization overhead

## Limitations

- Requires NVIDIA GPU hardware
- Host must have NVIDIA drivers and Container Toolkit installed
- Consumer GPU concurrent encoding session limits
- Not suitable for AMD or Intel GPUs (use hwaccel variant)
- Larger base image size due to Ubuntu + CUDA layers
- UID 1001 differs from other variants (1000)

## Differences from Other Variants

- **UID/GID**: Uses 1001 instead of 1000
- **Base Image**: Ubuntu (CUDA) instead of Alpine
- **Package Manager**: APT instead of APK
- **Image Size**: Larger due to CUDA runtime
- **Config Path**: Same as rootless/hwaccel variants

## Related Variants

- **Default**: For CPU-only transcoding
- **Rootless**: For non-GPU rootless operation
- **Hardware Acceleration**: For Intel/AMD VA-API GPU support
