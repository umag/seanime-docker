# Default Container Specification

## Overview

The default Seanime container variant running as root user with standard FFmpeg.

## Image Details

- **Image Tag**: `umagistr/seanime:latest`
- **Base Image**: `alpine:latest`
- **Target**: `base` stage in Dockerfile
- **User**: `root` (UID 0)

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
  - `TARGETVARIANT` - Target variant (for ARM)
- **Build Steps**:
  1. Copy `go.mod` and `go.sum`
  2. Download Go modules
  3. Copy source code
  4. Copy frontend output from node-builder
  5. Build binary with:
     - CGO disabled
     - Trimmed path
     - Stripped symbols (`-ldflags="-s -w"`)
     - ARM v7 support when `TARGETARCH=arm` and `TARGETVARIANT=v7`
- **Output**: Binary at `/tmp/build/seanime`

### Stage 3: Final Image

- **Base**: `alpine:latest` via `common-base`
- **Installed Packages**:
  - `ca-certificates` - SSL/TLS certificates
  - `tzdata` - Timezone data
  - `curl` - HTTP client (for healthcheck)
  - `ffmpeg` - Standard FFmpeg from Alpine repos

## Runtime Configuration

### Binary Location

- Path: `/app/seanime`
- Permissions: Executable

### Working Directory

- `/app`

### Exposed Ports

- `43211` - Web interface and API

### Volumes

Default mount points (from examples):

- `/root/.config/Seanime` - Application configuration
- `/anime` - Anime library directory
- `/downloads` - Downloads directory

### Health Check

- **Interval**: 30 seconds
- **Timeout**: 10 seconds
- **Start Period**: 5 seconds
- **Retries**: 3
- **Command**: `curl -f http://localhost:43211 || exit 1`

### Environment Variables

None required for basic operation.

### Entrypoint/Command

- **CMD**: `["/app/seanime"]`

## Security Considerations

### User & Permissions

- Runs as **root** (UID 0, GID 0)
- File ownership: root:root
- ⚠️ **Security Note**: This variant runs with elevated privileges. Consider
  using the rootless variant for improved security.

### Capabilities

- Full root capabilities available
- No capability restrictions

## Use Cases

- Development environments
- Scenarios requiring root access
- Legacy deployments
- When file permission management is complex

## Platform Support

- **Architectures**: amd64, arm64, arm/v7
- **OS**: Linux

## Dependencies

- Docker Engine
- Network access to AniList API
- Optional: Torrent clients for download integration

## Example Deployment

### Docker Compose

```yaml
services:
    seanime:
        image: umagistr/seanime:latest
        container_name: seanime
        ports:
            - "3211:43211"
        volumes:
            - ./seanime-config:/root/.config/Seanime
            - ./anime:/anime
            - ./downloads:/downloads
        restart: unless-stopped
```

### Docker Run

```bash
docker run -d \
  --name seanime \
  -p 3211:43211 \
  -v ./seanime-config:/root/.config/Seanime \
  -v ./anime:/anime \
  -v ./downloads:/downloads \
  --restart unless-stopped \
  umagistr/seanime:latest
```

## Limitations

- Requires root access to container filesystem
- May conflict with rootless Docker deployments
- Higher security risk profile

## Related Variants

- **Rootless**: For non-root operation
- **Hardware Acceleration**: For Intel/VA-API GPU support
- **CUDA**: For NVIDIA GPU support
