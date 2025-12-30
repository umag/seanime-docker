#!/usr/bin/env bats

setup_file() {
    # Define project root
    export PROJECT_ROOT="$(git rev-parse --show-toplevel)"
    export SCRIPT_DIR="$PROJECT_ROOT/scripts"
    
    # Ensure Goss binary is available
    if ! "$SCRIPT_DIR/ensure-goss.sh"; then
        echo "Failed to setup Goss" >&2
        return 1
    fi
    
    # Get the binary path (it's printed by the script)
    export GOSS_PATH="$("$SCRIPT_DIR/ensure-goss.sh")"
    export DGOSS="$SCRIPT_DIR/dgoss"
    
    # Pull images
    echo "Pulling images..." >&3
    docker pull umagistr/seanime:latest
    docker pull umagistr/seanime:latest-rootless
    docker pull umagistr/seanime:latest-hwaccel
    docker pull umagistr/seanime:latest-cuda
}

setup() {
    export PROJECT_ROOT="$(git rev-parse --show-toplevel)"
    export SCRIPT_DIR="$PROJECT_ROOT/scripts"
    # Re-export variables needed for tests as setup_file vars aren't always persisted to test scope depending on bats version
    # Actually, we need to run ensure-goss to get path again or just assume standard location if downloaded
    # But let's re-run the cheap check
    if [ -f "$SCRIPT_DIR/goss-linux-amd64" ]; then
         export GOSS_PATH="$SCRIPT_DIR/goss-linux-amd64"
    elif command -v goss >/dev/null; then
         export GOSS_PATH="$(command -v goss)"
    fi
    export DGOSS="$SCRIPT_DIR/dgoss"
    export GOSS_FILES_PATH="$PROJECT_ROOT/tests"
}

@test "latest: structure tests" {
    run container-structure-test test --image umagistr/seanime:latest --config "$PROJECT_ROOT/tests/structure-tests.yaml"
    [ "$status" -eq 0 ]
}

@test "latest: goss tests" {
    export GOSS_FILE="goss-default.yaml"
    run "$DGOSS" run umagistr/seanime:latest
    [ "$status" -eq 0 ]
}

@test "latest-rootless: structure tests" {
    run container-structure-test test --image umagistr/seanime:latest-rootless --config "$PROJECT_ROOT/tests/structure-tests.yaml"
    [ "$status" -eq 0 ]
}

@test "latest-rootless: goss tests" {
    export GOSS_FILE="goss-rootless.yaml"
    run "$DGOSS" run umagistr/seanime:latest-rootless
    [ "$status" -eq 0 ]
}

@test "latest-hwaccel: structure tests" {
    run container-structure-test test --image umagistr/seanime:latest-hwaccel --config "$PROJECT_ROOT/tests/structure-tests.yaml"
    [ "$status" -eq 0 ]
}

@test "latest-hwaccel: goss tests" {
    export GOSS_FILE="goss-hwaccel.yaml"
    run "$DGOSS" run umagistr/seanime:latest-hwaccel
    [ "$status" -eq 0 ]
}

@test "latest-cuda: structure tests" {
    run container-structure-test test --image umagistr/seanime:latest-cuda --config "$PROJECT_ROOT/tests/structure-tests.yaml"
    [ "$status" -eq 0 ]
}

@test "latest-cuda: goss tests" {
    export GOSS_FILE="goss-cuda.yaml"
    run "$DGOSS" run umagistr/seanime:latest-cuda
    [ "$status" -eq 0 ]
}
