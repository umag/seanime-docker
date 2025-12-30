# Workflows Specification

## New Workflow Architecture (2025)

The workflow system has been redesigned to integrate testing before publishing
and enable CI for repository changes.

### Reusable Build and Test Workflow (`reusable-build-test.yml`)

- **Type**: Reusable workflow
- **Purpose**: Centralized build and test logic used by both CI and publish
  workflows
- **Inputs**:
  - `seanime_version`: Seanime version tag to build
- **Jobs**:
  - `build_and_test`:
    - **Strategy**: Matrix with variants (`default`, `rootless`, `hwaccel`,
      `cuda`)
    - **Parallelism**: All variants build and test in parallel
    - **Steps**:
      1. Checkout repository
      2. Free disk space
      3. Setup QEMU and Docker Buildx
      4. Run `scripts/prepare.sh` with specified version
      5. Get CUDA version (for CUDA variant only)
      6. Build image for `linux/amd64` and load to Docker daemon
      7. Save build cache to GitHub Actions Cache
      8. Install test dependencies (BATS, container-structure-test, Goss)
         - BATS installed via npm
         - container-structure-test downloaded from Google Cloud Storage
         - Goss binary downloaded automatically by `scripts/ensure-goss.sh` when
           not present
      9. Run BATS tests from `tests/images.bats` for the specific variant

### CI Workflow (`ci.yml`)

- **Purpose**: Test Docker builds on repository code changes
- **Triggers**:
  - `push` to `main`/`master` branches
  - `pull_request` targeting `main`/`master` branches
  - **Paths**: `scripts/**`, `examples/**`, `Dockerfile*`, `tests/**`,
    `.github/workflows/**`
- **Jobs**:
  - `get_version`: Reads current version from `.version` file
  - `test`: Calls `reusable-build-test.yml` with current version

### Build, Test and Publish Workflow (`build-test-publish.yml`)

- **Purpose**: Check for new Seanime releases, test, and publish if tests pass
- **Triggers**:
  - Manual (`workflow_dispatch`)
  - Repository dispatch (`seanime_release`)
  - Scheduled (hourly: `0 * * * *`)
- **Jobs**:
  1. **`check`**:
     - Checks for new release of `5rahim/seanime`
     - Compares with `.version` file
     - Gets CUDA version
     - **Outputs**: `build_needed`, `version`, `cuda_version`

  2. **`test`**:
     - **Condition**: Only if new version detected
     - Calls `reusable-build-test.yml` with detected version
     - Tests all 4 variants in parallel

  3. **`publish`**:
     - **Condition**: Only if `check` found new version AND `test` passed
     - **Strategy**: Matrix with variants (`default`, `rootless`, `hwaccel`,
       `cuda`)
     - **Parallelism**: All variants publish in parallel
     - **Steps** (per variant):
       - Setup QEMU and Docker Buildx
       - Login to Docker Hub
       - Prepare repository
       - Build multi-arch images (`linux/amd64,linux/arm64,linux/arm/v7` or
         `linux/amd64` for CUDA)
       - Use cache from test job (`cache-from: type=gha`) to avoid rebuilding
         tested architecture
       - Push with proper tags:
         - **Default**: `latest`, `<version>`
         - **Rootless**: `latest-rootless`, `<version>-rootless`
         - **HwAccel**: `latest-hwaccel`, `<version>-hwaccel`
         - **CUDA**: `latest-cuda`, `<version>-cuda`,
           `<version>-cuda-<cuda-version>`

  4. **`finalize`**:
     - **Condition**: Only if publish succeeded
     - Updates `.version` file
     - Commits and pushes to git

### Legacy Workflows

#### Publish Docker image (`publish.yml`)

- **Status**: Replaced by `build-test-publish.yml`
- Can be disabled or removed to avoid conflicts

#### Test Docker Images (`test.yml`)

- **Status**: Replaced by reusable workflow integration
- Previously ran after publish; now integrated before publish

#### Test Compose Examples (`test-examples.yml`)

- **Status**: Still active
- **Purpose**: Verify Docker Compose examples are functional
- **Trigger**:
  - `workflow_run` (after `Publish Docker image` completes)
  - Manual (`workflow_dispatch`)
- **Jobs**:
  - `test_examples`:
    - Matrix strategy testing:
      - `01-default`
      - `02-rootless`
      - _Note_: `03-hwaccel` and `04-hwaccel-cuda` are skipped as they require
        specific hardware/drivers not available on standard runners
    - Steps:
      - Checkout repository
      - Run `docker compose up -d` in the example directory
      - Wait for server to start (check port 3211)
      - Run `docker compose down`

#### Docs (`docs.yml`)

- **Status**: Active
- Builds and deploys documentation

## Key Improvements

1. **Testing Before Publishing**: Images are tested before being pushed to
   Docker Hub
2. **No Redundant Builds**: GitHub Actions Cache ensures the publish step reuses
   layers from the test step
3. **Parallelization**: All variants build/test/publish in parallel for faster
   execution
4. **CI Integration**: Repository changes trigger builds and tests automatically
5. **Reusability**: Single source of truth for build/test logic via reusable
   workflow
6. **BATS Integration**: Uses existing BATS tests from `tests/images.bats`
   instead of inline bash

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
