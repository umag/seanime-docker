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

## New Workflow: Test Docker Images (`test.yml`)

### Purpose

To verify that the built Docker images can start and the web server inside
becomes responsive.

### Trigger

- `workflow_run`:
  - Workflows: ["Publish Docker image"]
  - Types: [completed]

### Job: `test_images`

- **Conditions**: Run only if the triggering workflow conclusion was `success`.
- **Steps**:
  1. Checkout repository.
  2. Determine the version tag to test (latest or specific version).
     - _Note_: Since the publish workflow runs on schedule, we should probably
       test `latest` or fetch the version from `.version` file or the artifacts
       if available. Testing `latest` variants is straightforward.
  3. Define the images to test:
     - `umagistr/seanime:latest`
     - `umagistr/seanime:latest-rootless`
     - `umagistr/seanime:latest-hwaccel`
     - `umagistr/seanime:latest-cuda` (Note: CUDA image might fail if run on
       non-CUDA runner, but the web server might still start if it falls back or
       if the check is just for the process. We might need to skip CUDA if
       runners don't support it or if it requires GPU to start).
  4. For each image:
     - Pull the image.
     - Run the container in detached mode, exposing port 43211 (default seanime
       port).
     - Wait for a few seconds.
     - Perform a `curl` check against `http://localhost:43211` (or appropriate
       endpoint).
     - Check logs if failure.
     - Stop and remove container.

### Considerations

- **CUDA Image**: GitHub Actions runners (standard) do not have GPUs. If the
  Seanime application requires a GPU to start in the CUDA variant, this test
  will fail. If it gracefully falls back or only fails when transcoding is
  attempted, the web server test might pass. I will assume for now we try to
  test it, or maybe exclude it if it's known to fail without GPU.
- **Port**: Seanime uses 43211 by default.
- **Rootless**: Might require specific docker flags or setup, but usually
  `docker run` handles it if built correctly.
