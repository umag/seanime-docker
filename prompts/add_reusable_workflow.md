# Add Reusable Build and Test Workflow

## User Intention

Create a comprehensive CI/CD workflow system that:

1. Tests Docker images on every code change (push/PR)
2. Only publishes to Docker Hub after successful tests
3. Avoids redundant builds by using caching
4. Runs tests in parallel for all variants

## Design Choices

### Modular Approach

- **Reusable Workflow** (`reusable-build-test.yml`): Contains the build and test
  logic
- **CI Workflow** (`ci.yml`): Triggers on code changes
- **Publish Workflow** (`publish.yml`): Triggers on schedule, checks for new
  Seanime releases

### Caching Strategy

- Test job builds for `amd64` and stores layers in GitHub Actions Cache
- Publish job reuses cached layers when building multi-arch images
- This avoids rebuilding the tested architecture

### Parallelization

- Matrix strategy tests all variants (default, rootless, hwaccel, cuda) in
  parallel
- Each variant builds and tests independently

### Testing Approach

- Build test images for `linux/amd64` (compatible with GitHub runners)
- Load images to local Docker daemon
- Run containers and verify health (HTTP check on port 43211)
- Hardware-specific variants (hwaccel, cuda) test basic functionality without
  full hardware access

## Implementation Steps

1. Create reusable workflow for build and test logic
2. Create CI workflow triggered by code changes
3. Update publish workflow to use reusable workflow and add publish step
4. Update specifications documentation
