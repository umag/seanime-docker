# Fix Permission Denied Error for Rootless Container on GitHub Runners

## Problem

The rootless container (and other non-root variants like hwaccel and cuda) were
failing on GitHub Actions with the error:

```
Failed to initialize config error="open /home/seanime/.config/Seanime/config.toml: permission denied"
```

This occurred during the BATS compose tests when running on GitHub runners.

## Root Cause

When Docker Compose creates volume mount directories like `./seanime-config` on
GitHub runners, they are created with root ownership by default. The rootless
container runs as UID 1000 (seanime user), which cannot write to root-owned
directories.

### Why This Happens on GitHub Runners

1. GitHub runners execute with elevated privileges
2. Docker creates missing volume directories as root
3. The container runs as UID 1000 (non-root)
4. UID 1000 cannot write to root-owned directories
5. Application fails to initialize config file

### Affected Variants

- `rootless` - runs as UID 1000
- `hwaccel` - runs as UID 1000
- `cuda` - runs as UID 1000

The `default` variant is not affected as it runs as root.

## Solution

Modified the BATS compose tests to explicitly create and set permissions for
volume directories before starting the containers:

```bash
echo "# Creating and setting permissions for volume directories..." >&3
mkdir -p ./seanime-config ./anime ./downloads
sudo chown -R 1000:1000 ./seanime-config ./anime ./downloads
echo "# Set ownership to 1000:1000 for rootless user" >&3
```

This ensures that:

1. Directories exist before Docker tries to create them
2. Directories have correct ownership (UID 1000, GID 1000)
3. The non-root container user can write to them

## Files Modified

### tests/compose.bats

Added permission setup before starting containers for these tests:

- `02-rootless` - Added before `docker compose up -d`
- `03-hwaccel` - Added before `docker compose up -d`
- `04-hwaccel-cuda` - Added before `docker compose up -d`

Example change:

```bash
@test "02-rootless: docker compose up and verify health" {
    # ... existing code ...
    
    echo "# Cleaning up existing containers..." >&3
    docker compose down || true
    
    # NEW: Set up permissions for non-root user
    echo "# Creating and setting permissions for volume directories..." >&3
    mkdir -p ./seanime-config ./anime ./downloads
    sudo chown -R 1000:1000 ./seanime-config ./anime ./downloads
    echo "# Set ownership to 1000:1000 for rootless user" >&3
    
    echo "# Starting docker compose..." >&3
    docker compose up -d
    
    # ... rest of test ...
}
```

## Benefits

1. **GitHub Actions Compatibility**: Tests now pass on GitHub runners
2. **Proper Permissions**: Volume directories have correct ownership for
   non-root users
3. **Clear Logging**: Added informative messages about permission setup
4. **Consistent Testing**: All non-root variants tested consistently
5. **Production Guidance**: Demonstrates proper permission setup pattern

## Testing

The fix ensures that:

- GitHub runners can successfully run compose tests for all variants
- Non-root containers can write to their config directories
- Tests accurately reflect real-world deployment scenarios
- Permission issues are caught and documented

## User Documentation Impact

This aligns with the existing documentation in
`specifications/container-rootless.md` which already mentions:

```bash
# Set ownership to UID 1000
sudo chown -R 1000:1000 ./seanime-config ./anime ./downloads
```

The fix demonstrates this recommendation directly in the test suite.

## Notes

- The `01-default` test was not modified since it runs as root
- Similar permission setup should be used in production deployments
- This pattern applies to any Docker container running as non-root
