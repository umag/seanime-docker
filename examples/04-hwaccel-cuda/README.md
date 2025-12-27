# NVIDIA CUDA Hardware Acceleration Setup

This setup enables NVIDIA Hardware Acceleration (NVENC/NVDEC) for transcoding.
It uses the NVIDIA CUDA base image and includes FFmpeg with NVENC support.

## Prerequisites

- **NVIDIA GPU** with NVENC support.
- **NVIDIA Drivers** installed on the host.
- **NVIDIA Container Toolkit** installed and configured on the host.
  - [Installation Guide](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)

## Usage

1. Create a `docker-compose.yml` file with the content provided in this
   directory.
2. Ensure your host directories have the correct permissions (writable by UID
   1001).
   ```bash
   sudo chown -R 1001:1001 ./seanime-config
   ```
3. Run `docker-compose up -d`.

## Configuration

- **Config Path**: `/home/seanime/.config/Seanime`
- **User**: Runs as `seanime` (UID 1001) inside the container.
- **Image**: `umagistr/seanime:latest-cuda`
- **GPU Access**: Configured via `runtime: nvidia` and environment variables.

## Important

- This variant is **amd64 only** (x86_64).
- Requires the NVIDIA Container Toolkit to pass the GPU to the container.
- By default, it uses all available GPUs (`NVIDIA_VISIBLE_DEVICES=all`). You can
  change this to a specific index (e.g., `0`) in the `docker-compose.yml`.
