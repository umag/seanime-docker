# Workflows Specification

## Existing Workflows

### Publish Docker image (`publish.yml`)

- **Trigger**:
  - Manual (`workflow_dispatch`)
  - Repository dispatch (`seanime_release`)
  - Scheduled (hourly)
- **Jobs**:
  - `check_and_build`:
    - Checks for a new release of `5rahim/seanime`.
    - Compares with `.version` file.
    - If new version detected:
      - Prepares repository.
      - Sets up QEMU and Docker Buildx.
      - Logs in to Docker Hub.
      - Builds and pushes 4 variants:
        1. **Default**: `umagistr/seanime:latest`, `umagistr/seanime:<version>`
        2. **Rootless**: `umagistr/seanime:latest-rootless`,
           `umagistr/seanime:<version>-rootless`
        3. **Hardware Acceleration**: `umagistr/seanime:latest-hwaccel`,
           `umagistr/seanime:<version>-hwaccel`
        4. **CUDA**: `umagistr/seanime:latest-cuda`,
           `umagistr/seanime:<version>-cuda`,
           `umagistr/seanime:<version>-cuda-<cuda-version>`
      - Updates `.version` file and pushes changes to git.

### Docs (`docs.yml`)

- Likely builds and deploys documentation (not analyzed in detail).

## Test Workflows

### Test Docker Images (`test.yml`)

- **Purpose**: Verify that the built Docker images can start and the web server
  inside becomes responsive.
- **Trigger**:
  - `workflow_run` (after `Publish Docker image` completes).
  - Manual (`workflow_dispatch`).
- **Jobs**:
  - `test_images`:
    - Tests images: `latest`, `latest-rootless`, `latest-hwaccel`,
      `latest-cuda`.
    - Runs containers using `docker run` in detached mode.
    - Checks connectivity to port 43211.
    - Fails if server doesn't respond within timeout.

### Test Compose Examples (`test-examples.yml`)

- **Purpose**: Verify that the provided Docker Compose examples are valid and
  functional.
- **Trigger**:
  - `workflow_run` (after `Publish Docker image` completes).
  - Manual (`workflow_dispatch`).
- **Jobs**:
  - `test_examples`:
    - Matrix strategy testing:
      - `01-default`
      - `02-rootless`
      - _Note_: `03-hwaccel` and `04-hwaccel-cuda` are skipped as they require
        specific hardware/drivers not available on standard runners.
    - Steps:
      - Checkout repository.
      - Run `docker compose up -d` in the example directory.
      - Wait for server to start (check port 3211).
      - Run `docker compose down`.

## Local Development Scripts

### Build Local Images (`scripts/build_local.sh`)

- **Purpose**: Run the prepare steps and build all Docker images locally for
  development and testing.
- **Usage**: `./scripts/build_local.sh [optional_tag]`
- **Steps**:
  - Fetches the latest release tag from `5rahim/seanime` (or uses provided tag).
  - Runs `scripts/prepare.sh`.
  - Builds `umagistr/seanime:latest`.
  - Builds `umagistr/seanime:latest-rootless`.
  - Builds `umagistr/seanime:latest-hwaccel`.
  - Fetches latest CUDA version using `scripts/get-cuda-version.sh`.
  - Updates `Dockerfile.cuda` temporarily.
  - Builds `umagistr/seanime:latest-cuda`.
  - Restores original `Dockerfile.cuda`.
