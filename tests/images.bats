#!/usr/bin/env bats

setup_file() {
    echo "=== Setting up test environment ===" >&3
    
    # Define project root
    export PROJECT_ROOT="$(git rev-parse --show-toplevel)"
    export SCRIPT_DIR="$PROJECT_ROOT/scripts"
    echo "Project root: $PROJECT_ROOT" >&3
    echo "Script directory: $SCRIPT_DIR" >&3
    
    # Ensure Goss binary is available
    echo "Ensuring Goss binary is available..." >&3
    if ! "$SCRIPT_DIR/ensure-goss.sh"; then
        echo "Failed to setup Goss" >&2
        return 1
    fi
    
    # Get the binary path (it's printed by the script)
    export GOSS_PATH="$("$SCRIPT_DIR/ensure-goss.sh")"
    export DGOSS="$SCRIPT_DIR/dgoss"
    echo "Goss path: $GOSS_PATH" >&3
    echo "dgoss path: $DGOSS" >&3
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
    echo "Running structure tests for umagistr/seanime:latest"
    echo "Config: $PROJECT_ROOT/tests/structure-tests.yaml"
    
    run container-structure-test test --image umagistr/seanime:latest --config "$PROJECT_ROOT/tests/structure-tests.yaml"
    
    if [ "$status" -ne 0 ]; then
        echo "FAILED: Structure tests failed with status $status"
        echo "Output:"
        echo "$output"
    else
        echo "PASSED: Structure tests successful"
    fi
    
    [ "$status" -eq 0 ]
}

@test "latest: goss tests" {
    export GOSS_FILE="goss-default.yaml"
    echo "Running Goss tests for umagistr/seanime:latest"
    echo "Goss file: $GOSS_FILE"
    echo "Command: $DGOSS run umagistr/seanime:latest"
    
    run "$DGOSS" run umagistr/seanime:latest
    
    if [ "$status" -ne 0 ]; then
        echo "FAILED: Goss tests failed with status $status"
        echo "Output:"
        echo "$output"
    else
        echo "PASSED: Goss tests successful"
    fi
    
    [ "$status" -eq 0 ]
}

@test "latest-rootless: structure tests" {
    echo "Running structure tests for umagistr/seanime:latest-rootless"
    echo "Config: $PROJECT_ROOT/tests/structure-tests.yaml"
    
    run container-structure-test test --image umagistr/seanime:latest-rootless --config "$PROJECT_ROOT/tests/structure-tests.yaml"
    
    if [ "$status" -ne 0 ]; then
        echo "FAILED: Structure tests failed with status $status"
        echo "Output:"
        echo "$output"
    else
        echo "PASSED: Structure tests successful"
    fi
    
    [ "$status" -eq 0 ]
}

@test "latest-rootless: goss tests" {
    export GOSS_FILE="goss-rootless.yaml"
    echo "Running Goss tests for umagistr/seanime:latest-rootless"
    echo "Goss file: $GOSS_FILE"
    echo "Command: $DGOSS run umagistr/seanime:latest-rootless"
    
    run "$DGOSS" run umagistr/seanime:latest-rootless
    
    if [ "$status" -ne 0 ]; then
        echo "FAILED: Goss tests failed with status $status"
        echo "Output:"
        echo "$output"
    else
        echo "PASSED: Goss tests successful"
    fi
    
    [ "$status" -eq 0 ]
}

@test "latest-hwaccel: structure tests" {
    echo "Running structure tests for umagistr/seanime:latest-hwaccel"
    echo "Config: $PROJECT_ROOT/tests/structure-tests.yaml"
    
    run container-structure-test test --image umagistr/seanime:latest-hwaccel --config "$PROJECT_ROOT/tests/structure-tests.yaml"
    
    if [ "$status" -ne 0 ]; then
        echo "FAILED: Structure tests failed with status $status"
        echo "Output:"
        echo "$output"
    else
        echo "PASSED: Structure tests successful"
    fi
    
    [ "$status" -eq 0 ]
}

@test "latest-hwaccel: goss tests" {
    export GOSS_FILE="goss-hwaccel.yaml"
    echo "Running Goss tests for umagistr/seanime:latest-hwaccel"
    echo "Goss file: $GOSS_FILE"
    echo "Command: $DGOSS run umagistr/seanime:latest-hwaccel"
    
    run "$DGOSS" run umagistr/seanime:latest-hwaccel
    
    if [ "$status" -ne 0 ]; then
        echo "FAILED: Goss tests failed with status $status"
        echo "Output:"
        echo "$output"
    else
        echo "PASSED: Goss tests successful"
    fi
    
    [ "$status" -eq 0 ]
}

@test "latest-cuda: structure tests" {
    echo "Running structure tests for umagistr/seanime:latest-cuda"
    echo "Config: $PROJECT_ROOT/tests/structure-tests.yaml"
    
    run container-structure-test test --image umagistr/seanime:latest-cuda --config "$PROJECT_ROOT/tests/structure-tests.yaml"
    
    if [ "$status" -ne 0 ]; then
        echo "FAILED: Structure tests failed with status $status"
        echo "Output:"
        echo "$output"
    else
        echo "PASSED: Structure tests successful"
    fi
    
    [ "$status" -eq 0 ]
}

@test "latest-cuda: goss tests" {
    export GOSS_FILE="goss-cuda.yaml"
    echo "Running Goss tests for umagistr/seanime:latest-cuda"
    echo "Goss file: $GOSS_FILE"
    echo "Command: $DGOSS run umagistr/seanime:latest-cuda"
    
    run "$DGOSS" run umagistr/seanime:latest-cuda
    
    if [ "$status" -ne 0 ]; then
        echo "FAILED: Goss tests failed with status $status"
        echo "Output:"
        echo "$output"
    else
        echo "PASSED: Goss tests successful"
    fi
    
    [ "$status" -eq 0 ]
}
