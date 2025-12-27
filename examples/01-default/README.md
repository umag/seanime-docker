# Basic Setup (Default)

This is the standard setup for Seanime running as the root user.

## Usage

1. Create a `docker-compose.yml` file with the content provided in this
   directory.
2. Run `docker-compose up -d`.

## Configuration

- **Config Path**: `/root/.config/Seanime`
- **User**: Runs as `root` inside the container.
- **Image**: `umagistr/seanime:latest`

This configuration ensures compatibility with existing setups.
