# Rootless Setup

This setup runs Seanime as a non-root user (UID 1000) for improved security.

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
- **Image**: `umagistr/seanime:latest-rootless`

## Important

If migrating from the default root-based image, you must update your volume
mappings and fix permissions.
