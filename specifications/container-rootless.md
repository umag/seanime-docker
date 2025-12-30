# Rootless Container Specification

## Overview

The rootless Seanime container variant running as non-privileged user with
standard FFmpeg.

## Image Details

- **Image Tag**: `umagistr/seanime:latest-rootless`
- **Base Image**: `alpine:latest`
- **Target**: `rootless` stage in Dockerfile
- **User**: `seanime` (UID 1000, GID 1000)

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
- **User Creation**:
  - Group: `seanime` (GID 1000)
  - User: `seanime` (UID 1000)
  - Shell: `/sbin/nologin`
  - No home directory login
- **Installed Packages**:
  - `ca-certificates` - SSL/TLS certificates
  - `tzdata` - Timezone data
  - `curl` - HTTP client (for healthcheck)
  - `ffmpeg` - Standard FFmpeg from Alpine repos

## Runtime Configuration

### Binary Location

- Path: `/app/seanime`
- Permissions: Executable
- Owner: `seanime:seanime` (1000:1000)

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
1000 / GID 1000.

### Health Check

- **Interval**: 30 seconds
- **Timeout**: 10 seconds
- **Start Period**: 5 seconds
- **Retries**: 3
- **Command**: `curl -f http://localhost:43211 || exit 1`

### Environment Variables

None required for basic operation.

### Entrypoint/Command

- **USER**: `1000`
- **CMD**: `["/app/seanime"]`

## Security Considerations

### User & Permissions

- Runs as **non-root** user `seanime` (UID 1000, GID 1000)
- File ownership: `seanime:seanime` (1000:1000)
- Shell: `/sbin/nologin` - prevents shell access
- ✅ **Security Benefit**: Reduced attack surface and privilege separation

### Capabilities

- No special capabilities required
- Limited to non-root user permissions
- Cannot bind to privileged ports (<1024)

### File System Access

- Container process can only access files readable/writable by UID 1000
- Host directories must be configured with appropriate permissions

## Use Cases

- Production deployments
- Security-conscious environments
- Multi-tenant systems
- Compliance requirements
- Recommended for most use cases

## Platform Support

- **Architectures**: amd64, arm64, arm/v7
- **OS**: Linux

## Dependencies

- Docker Engine
- Network access to AniList API
- Optional: Torrent clients for download integration
- Host filesystem permissions for UID 1000

## Example Deployment

### Docker Compose

```yaml
services:
  seanime:
    image: umagistr/seanime:latest-rootless
    container_name: seanime
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
  -p 3211:43211 \
  -v ./seanime-config:/home/seanime/.config/Seanime \
  -v ./anime:/anime \
  -v ./downloads:/downloads \
  --restart unless-stopped \
  umagistr/seanime:latest-rootless
```

### Setting Permissions on Host

Ensure host directories have appropriate permissions:

```bash
# Set ownership to UID 1000
sudo chown -R 1000:1000 ./seanime-config ./anime ./downloads

# Or give world-writable permissions (less secure)
chmod -R 777 ./seanime-config ./anime ./downloads
```

## Migration from Root Variant

When migrating from the default (root) variant:

1. Stop the existing container
2. Change ownership of mounted volumes:
   ```bash
   sudo chown -R 1000:1000 /path/to/seanime-config
   ```
3. Update docker-compose.yml to use `latest-rootless` tag
4. Update volume paths to `/home/seanime/.config/Seanime`
5. Start the new container

## Limitations

- Cannot bind to privileged ports (<1024) without additional configuration
- Requires proper host filesystem permissions
- May need manual permission adjustment when migrating from root variant

## Troubleshooting

### Permission Denied Errors

If you encounter permission errors:

```bash
# Fix ownership
sudo chown -R 1000:1000 ./seanime-config ./anime ./downloads

# Or use user namespace remapping in Docker
```

### Cannot Access Volumes

Ensure the host directories exist and have correct permissions before starting
the container.

### CI/CD Testing on GitHub Actions

When testing on GitHub Actions or other CI/CD environments where Docker runs
with elevated privileges, volume directories must have correct ownership set
before container startup:

```bash
# Create and set permissions before docker compose up
mkdir -p ./seanime-config ./anime ./downloads
sudo chown -R 1000:1000 ./seanime-config ./anime ./downloads
```

This prevents the "permission denied" error that occurs when Docker creates
directories as root but the container runs as UID 1000.

## Related Variants

- **Default**: For root operation
- **Hardware Acceleration**: For Intel/VA-API GPU support with non-root user
- **CUDA**: For NVIDIA GPU support with non-root user
