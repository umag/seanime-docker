# Hardware Acceleration Container Specification

## Overview

The hardware acceleration Seanime container variant with Intel VA-API and
Jellyfin FFmpeg support for GPU-accelerated video transcoding.

## Image Details

- **Image Tag**: `umagistr/seanime:latest-hwaccel`
- **Base Image**: `alpine:latest`
- **Target**: `hwaccel` stage in Dockerfile
- **User**: `seanime` (UID 1000, GID 1000)
- **FFmpeg**: Jellyfin FFmpeg with hardware acceleration support

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
- **Repository Configuration**:
  - Enables Alpine community repository
  - Adds Jellyfin repository: `https://repo.jellyfin.org/releases/alpine/`
- **Installed Packages**:
  - `ca-certificates` - SSL/TLS certificates
  - `tzdata` - Timezone data
  - `curl` - HTTP client (for healthcheck)
  - `jellyfin-ffmpeg` - FFmpeg with hardware acceleration
  - `mesa-va-gallium` - VA-API support for AMD/generic GPUs
  - `opencl-icd-loader` - OpenCL support
  - **AMD64 only**:
    - `intel-media-driver` - Intel Gen 8+ GPU support
    - `libva-intel-driver` - Intel Gen 1-7 GPU support
- **FFmpeg Setup**:
  - Binaries located at `/usr/lib/jellyfin-ffmpeg/`
  - Symlinks created: `/usr/bin/ffmpeg` → `/usr/lib/jellyfin-ffmpeg/ffmpeg`
  - Symlinks created: `/usr/bin/ffprobe` → `/usr/lib/jellyfin-ffmpeg/ffprobe`
  - Executable permissions: `+x` on ffmpeg and ffprobe

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

### Device Access

**Required** for hardware acceleration:

- `/dev/dri:/dev/dri` - Direct Rendering Infrastructure (GPU access)

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

## Hardware Support

### Intel GPUs

- **Supported Generations**:
  - Gen 8+ (Broadwell and newer): Uses `intel-media-driver` (iHD)
  - Gen 1-7 (Sandy Bridge to Haswell): Uses `libva-intel-driver` (i965)
- **Features**:
  - H.264/AVC encoding/decoding
  - H.265/HEVC encoding/decoding
  - VP9 decoding (Gen 9+)
  - AV1 decoding (Gen 11+)

### AMD GPUs

- **Driver**: `mesa-va-gallium`
- **Features**:
  - H.264/AVC encoding/decoding
  - H.265/HEVC encoding/decoding (RDNA and newer)
  - VP9 decoding

### ARM Devices

- Base support via `mesa-va-gallium`
- Hardware support depends on specific ARM SoC capabilities

## Security Considerations

### User & Permissions

- Runs as **non-root** user `seanime` (UID 1000, GID 1000)
- File ownership: `seanime:seanime` (1000:1000)
- ✅ **Security Benefit**: Reduced attack surface with privilege separation
- User must have access to `/dev/dri` device (usually via `video` group on host)

### Device Access

- Requires access to `/dev/dri` for hardware acceleration
- User should be member of `video` group on host for device access
- Risk: Direct hardware access, though mitigated by non-root user

### Capabilities

- No special capabilities required beyond device access
- Limited to non-root user permissions

## Use Cases

- Transcoding anime videos for streaming
- Hardware-accelerated video processing
- Systems with Intel or AMD integrated/discrete GPUs
- Reducing CPU usage during video operations
- Production deployments requiring efficient video handling

## Platform Support

- **Architectures**: amd64 (full support), arm64 (limited)
- **OS**: Linux
- **GPU**: Intel (Gen 1+), AMD (with VA-API support)
- **Note**: Intel drivers only installed on amd64 builds

## Dependencies

- Docker Engine
- Intel or AMD GPU with VA-API support
- `/dev/dri` device access
- Network access to AniList API
- Optional: Torrent clients for download integration
- Host filesystem permissions for UID 1000

## Example Deployment

### Docker Compose

```yaml
services:
  seanime:
    image: umagistr/seanime:latest-hwaccel
    container_name: seanime
    devices:
      - /dev/dri:/dev/dri
    group_add:
      - video
      - render
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
  --device /dev/dri:/dev/dri \
  --group-add video \
  --group-add render \
  -p 3211:43211 \
  -v ./seanime-config:/home/seanime/.config/Seanime \
  -v ./anime:/anime \
  -v ./downloads:/downloads \
  --restart unless-stopped \
  umagistr/seanime:latest-hwaccel
```

## Verification

### Check GPU Access

```bash
# Inside the container
docker exec seanime ls -la /dev/dri
# Should show render and card devices

# Check VA-API capabilities
docker exec seanime vainfo
```

### Test FFmpeg Hardware Acceleration

```bash
# Check available encoders
docker exec seanime ffmpeg -encoders | grep vaapi

# Check available decoders
docker exec seanime ffmpeg -decoders | grep vaapi
```

## Troubleshooting

### Permission Denied on /dev/dri

The container is configured to run with the `video` and `render` groups from the
host system. Ensure these groups exist and have access to `/dev/dri`:

1. Check group ownership of GPU devices:
   ```bash
   ls -la /dev/dri/
   # Should show video and/or render group ownership
   ```

2. If needed, add your user to these groups on host:
   ```bash
   sudo usermod -aG video $(whoami)
   sudo usermod -aG render $(whoami)
   # Reboot or re-login for changes to take effect
   ```

3. Verify group IDs match:
   ```bash
   getent group video render
   # Note the GID values
   ```

### Hardware Acceleration Not Working

1. Verify GPU support:
   ```bash
   docker exec seanime vainfo
   ```

2. Check device permissions:
   ```bash
   ls -la /dev/dri/
   # Should show renderD128 and card0 (or similar)
   ```

3. Ensure correct drivers are installed on host system

### FFmpeg Not Using Hardware

- Check Seanime transcoding settings
- Verify FFmpeg was built with VA-API support:
  ```bash
  docker exec seanime ffmpeg -hwaccels
  # Should list 'vaapi'
  ```

## Performance Considerations

- Hardware acceleration significantly reduces CPU usage during transcoding
- Transcode quality may differ slightly from software encoding
- First-time hardware init may have slight latency
- Multiple concurrent transcodes share GPU resources

## Limitations

- Intel drivers only available on amd64 architecture
- ARM support limited to devices with VA-API capable GPUs
- Requires physical GPU access (not suitable for cloud VMs without GPU
  passthrough)
- Some advanced FFmpeg features may not be hardware-accelerated

## Related Variants

- **Default**: For systems without GPU or software-only transcoding
- **Rootless**: For non-accelerated rootless operation
- **CUDA**: For NVIDIA GPU acceleration
