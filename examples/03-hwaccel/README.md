# Hardware Acceleration Setup

This setup enables Intel Hardware Acceleration (QSV/VAAPI) for transcoding. It
uses the rootless variant as a base.

## Prerequisites

- **Intel CPU** with Quick Sync Video support (amd64 architecture only).
- Docker must have access to `/dev/dri` on the host.

## Usage

1. Create a `docker-compose.yml` file with the content provided in this
   directory.
2. Ensure your host directories have the correct permissions (writable by UID
   1000).
   ```bash
   sudo chown -R 1000:1000 ./seanime-config
   ```
3. Run `docker-compose up -d`.

## Configuration

- **Config Path**: `/home/seanime/.config/Seanime`
- **User**: Runs as `seanime` (UID 1000) inside the container.
- **Image**: `umagistr/seanime:latest-hwaccel`
- **Devices**: Passes `/dev/dri` to the container.

## Important

- This variant is **amd64 only** for hardware acceleration features.
- It falls back to software transcoding on other architectures but includes the
  improved Jellyfin-FFmpeg.
