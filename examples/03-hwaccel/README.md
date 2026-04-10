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
3. Ensure your user is in the `video` and `render` groups on the host (if they
   exist):
   ```bash
   sudo usermod -aG video,render $(whoami)
   # Log out and back in, or reboot for changes to take effect
   ```
4. Run `docker-compose up -d`.

## Configuration

- **Config Path**: `/home/seanime/.config/Seanime`
- **User**: Runs as `seanime` (UID 1000) inside the container.
- **Image**: `umagistr/seanime:latest-hwaccel`
- **Devices**: Passes `/dev/dri` to the container.
- **Groups**: Container user added to host `video` and `render` groups for GPU
  access.

## Custom UID/GID

If your media library uses different ownership, set the `user` field in
docker-compose.yml:

```yaml
user: "1000:1500"
```

Then chown your volumes to match:

```bash
sudo chown -R 1000:1500 ./seanime-config
```

The `group_add` directive for `video` and `render` continues to work alongside
`user:` — it uses host group IDs which are unaffected by the UID:GID override.

## Important

- This variant is **amd64 only** for hardware acceleration features.
- It falls back to software transcoding on other architectures but includes the
  improved Jellyfin-FFmpeg.
