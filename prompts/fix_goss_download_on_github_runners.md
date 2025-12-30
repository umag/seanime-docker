# Fix Goss Binary Download on GitHub Runners

## Problem

The GitHub Actions workflow was failing with error:

```
ERROR: Could not find or download compatible Goss binary.
```

This occurred because the `ensure-goss.sh` script only downloaded Goss on macOS,
but expected it to be pre-installed on Linux systems (like GitHub runners).
Since Goss is not pre-installed on GitHub runners, the script would fail.

## Root Cause

In `scripts/ensure-goss.sh`, the Linux branch only checked if Goss was already
installed:

```bash
if [ "$OS" == "Linux" ]; then
    if command -v goss &> /dev/null; then
        GOSS_BINARY=$(command -v goss)
    fi
    # No download fallback - would fail here
fi
```

## Solution

Modified `scripts/ensure-goss.sh` to explicitly download Goss on Linux systems
when it's not found:

```bash
if [ "$OS" == "Linux" ]; then
    if command -v goss &> /dev/null; then
        GOSS_BINARY=$(command -v goss)
        echo "Found existing Goss installation: $GOSS_BINARY"
    else
        # Download Goss if not found (e.g., on GitHub runners)
        if [ -f "$SCRIPT_DIR/goss-linux-amd64" ]; then
            GOSS_BINARY="$SCRIPT_DIR/goss-linux-amd64"
            echo "Using cached Goss binary: $GOSS_BINARY"
        else
            echo "Goss not found. Downloading Linux version of Goss..."
            curl -L https://github.com/goss-org/goss/releases/latest/download/goss-linux-amd64 -o "$SCRIPT_DIR/goss-linux-amd64"
            chmod +x "$SCRIPT_DIR/goss-linux-amd64"
            GOSS_BINARY="$SCRIPT_DIR/goss-linux-amd64"
            echo "Downloaded Goss binary: $GOSS_BINARY"
        fi
    fi
fi
```

## Benefits

1. **Automatic Download**: Goss is now downloaded automatically on Linux when
   not found
2. **Caching**: Checks for existing cached binary before downloading
3. **Better Logging**: Added informative messages about what's happening
4. **Consistent Behavior**: Linux and macOS now both have download fallback
   logic
5. **No Manual Installation**: GitHub runners no longer require pre-installing
   Goss

## Files Modified

- `scripts/ensure-goss.sh`: Added explicit download logic for Linux systems
- `specifications/workflows.md`: Updated documentation to reflect automatic Goss
  download

## Testing

The fix ensures that:

- GitHub runners can run tests without pre-installing Goss
- Local Linux systems can use either system-installed or downloaded Goss
- The script maintains backward compatibility with existing setups
- macOS behavior remains unchanged (still downloads Linux version for container
  compatibility)
