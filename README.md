# Seanime Docker

[![Docker Pulls](https://img.shields.io/docker/pulls/umagistr/seanime.svg)](https://hub.docker.com/r/umagistr/seanime)
[![Publish Docker image](https://github.com/umag/seanime-docker/actions/workflows/publish.yml/badge.svg)](https://github.com/umag/seanime-docker/actions/workflows/publish.yml)

A simple, multi-arch Docker image for [Seanime](https://seanime.rahim.app/).

## Image Variants

We provide three image variants to suit different needs:

| Variant      | Tag               | User                | Description                                             |
| ------------ | ----------------- | ------------------- | ------------------------------------------------------- |
| **Default**  | `latest`          | `root`              | Standard setup (Alpine + FFmpeg). Backward compatible.  |
| **Rootless** | `latest-rootless` | `seanime` (1000)    | Security-focused, runs as non-root user.                |
| **HwAccel**  | `latest-hwaccel`  | `seanime` (1000)    | Rootless + Jellyfin-FFmpeg + Intel Drivers (QSV/VAAPI). |
| **CUDA**     | `latest-cuda`     | `seanime` (1001!!!) | Rootless + FFmpeg (NVENC) + NVIDIA CUDA Base.           |

## Usage

### Quick Start (Default)

The default image runs as root, similar to previous versions.

```yaml
services:
  seanime:
    image: umagistr/seanime:latest
    container_name: seanime
    volumes:
      - /mnt/user/anime:/anime
      - /mnt/user/downloads:/downloads
      - ./seanime-config:/root/.config/Seanime
    ports:
      - 3211:43211
    restart: unless-stopped
```

### Examples

Check the [examples](./examples) directory for complete configurations:

- **[01-Default](./examples/01-default)**: Standard root-based setup.
- **[02-Rootless](./examples/02-rootless)**: Secure non-root setup.
- **[03-HwAccel](./examples/03-hwaccel)**: Hardware acceleration (Intel) setup.
- **[04-CUDA](./examples/04-hwaccel-cuda)**: Hardware acceleration (NVIDIA CUDA)
  setup.

## Configuration

### Ports

`3211` - External port mapping to container's `43211`.

### Volumes

#### Default Variant

- `/root/.config/Seanime` - Configuration files.

#### Rootless & HwAccel Variants

- `/home/seanime/.config/Seanime` - Configuration files.
- **Note**: Ensure the host directory for config is writable by UID 1000.

#### Common

- `/anime` - Media library (mount your anime directory here).
- `/downloads` - Downloads directory.

## Hardware Acceleration

### Intel QSV/VAAPI

To use hardware acceleration (Intel QSV/VAAPI):

1. Use the `latest-hwaccel` tag.
2. Pass the device `/dev/dri` to the container.
3. Only supported on `amd64` architecture (falls back to software on others).

```yaml
services:
  seanime:
    image: umagistr/seanime:latest-hwaccel
    devices:
      - /dev/dri:/dev/dri
    # ... other config
```

### NVIDIA CUDA (NVENC/NVDEC)

To use NVIDIA hardware acceleration:

1. Use the `latest-cuda` tag.
2. Ensure NVIDIA drivers and Container Toolkit are installed on the host.
3. Configure the runtime to `nvidia`.

```yaml
services:
  seanime:
    image: umagistr/seanime:latest-cuda
    runtime: nvidia
    environment:
      - NVIDIA_VISIBLE_DEVICES=all
    # ... other config
```

## Development & Testing

This project uses [Nix](https://nixos.org/) and [direnv](https://direnv.net/) to
manage development dependencies.

### Setup

1. Install **Nix** and **direnv**.
2. Run `direnv allow` in the project root.
3. This will install:
   - `container-structure-test`
   - `goss` / `dgoss`
   - `bats`
   - `hadolint`

### Running Tests

We use **BATS** to orchestrate all tests.

#### 1. Image Verification (Structure & Goss)

This suite pulls all image variants and runs both Container Structure Tests and
Goss tests against them.

```bash
bats tests/images.bats
```

#### 2. Docker Compose Integration

This suite verifies the example Compose configurations.

```bash
bats tests/compose.bats
```
