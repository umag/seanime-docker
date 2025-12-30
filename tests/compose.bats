#!/usr/bin/env bats

setup() {
    # Define project root
    PROJECT_ROOT="$(git rev-parse --show-toplevel)"
    echo "# Project root: $PROJECT_ROOT" >&3
}

wait_for_health() {
    local service_name="$1"
    local max_retries=60
    local retry=0

    echo "# [HEALTH CHECK] Waiting for $service_name to be healthy..." >&3
    while [ $retry -lt $max_retries ]; do
        local health_status
        health_status=$(docker inspect --format='{{.State.Health.Status}}' "$service_name" 2>/dev/null || echo "not_found")
        
        if [ "$health_status" == "healthy" ]; then
            echo "# [HEALTH CHECK] ✓ $service_name is healthy!" >&3
            return 0
        fi

        echo "# [HEALTH CHECK] Retry $retry/$max_retries: Status is $health_status" >&3
        retry=$((retry + 1))
        sleep 2
    done

    echo "# [HEALTH CHECK] ✗ Timed out waiting for $service_name" >&3
    echo "# [LOGS] Container logs:" >&3
    docker logs "$service_name" >&3 2>&1
    return 1
}

@test "01-default: docker compose up and verify health" {
    echo "# ========================================" >&3
    echo "# TEST: 01-default (Root variant)" >&3
    echo "# ========================================" >&3
    
    cd "$PROJECT_ROOT/examples/01-default"
    echo "# Working directory: $(pwd)" >&3
    
    # Clean up any potential leftovers
    echo "# Cleaning up existing containers..." >&3
    docker compose down || true

    # Start
    echo "# Starting docker compose..." >&3
    docker compose up -d
    
    echo "# Listing running containers:" >&3
    docker compose ps >&3
    
    CONTAINER_ID=$(docker compose ps -q seanime)
    echo "# Container ID: $CONTAINER_ID" >&3
    [ -n "$CONTAINER_ID" ]

    echo "# Inspecting container configuration:" >&3
    docker inspect --format='User: {{.Config.User}}' "$CONTAINER_ID" >&3
    docker inspect --format='Image: {{.Config.Image}}' "$CONTAINER_ID" >&3

    run wait_for_health "$CONTAINER_ID"
    [ "$status" -eq 0 ]
    
    # Teardown
    echo "# Tearing down..." >&3
    docker compose down
    echo "# ✓ Test completed successfully" >&3
}

@test "02-rootless: docker compose up and verify health" {
    echo "# ========================================" >&3
    echo "# TEST: 02-rootless (Rootless variant)" >&3
    echo "# ========================================" >&3
    
    cd "$PROJECT_ROOT/examples/02-rootless"
    echo "# Working directory: $(pwd)" >&3
    
    echo "# Cleaning up existing containers..." >&3
    docker compose down || true
    
    echo "# Creating and setting permissions for volume directories..." >&3
    mkdir -p ./seanime-config ./anime ./downloads
    sudo chown -R 1000:1000 ./seanime-config ./anime ./downloads
    echo "# Set ownership to 1000:1000 for rootless user" >&3
    
    echo "# Starting docker compose..." >&3
    docker compose up -d
    
    echo "# Listing running containers:" >&3
    docker compose ps >&3

    CONTAINER_ID=$(docker compose ps -q seanime)
    echo "# Container ID: $CONTAINER_ID" >&3
    [ -n "$CONTAINER_ID" ]

    echo "# Inspecting container configuration:" >&3
    docker inspect --format='User: {{.Config.User}}' "$CONTAINER_ID" >&3
    docker inspect --format='Image: {{.Config.Image}}' "$CONTAINER_ID" >&3

    run wait_for_health "$CONTAINER_ID"
    [ "$status" -eq 0 ]
    
    echo "# Tearing down..." >&3
    docker compose down
    echo "# ✓ Test completed successfully" >&3
}

@test "03-hwaccel: docker compose up and verify health" {
    echo "# ========================================" >&3
    echo "# TEST: 03-hwaccel (Hardware Acceleration variant)" >&3
    echo "# ========================================" >&3
    
    cd "$PROJECT_ROOT/examples/03-hwaccel"
    echo "# Working directory: $(pwd)" >&3
    
    echo "# Cleaning up existing containers..." >&3
    docker compose down || true
    
    echo "# Creating and setting permissions for volume directories..." >&3
    mkdir -p ./seanime-config ./anime ./downloads
    sudo chown -R 1000:1000 ./seanime-config ./anime ./downloads
    echo "# Set ownership to 1000:1000 for hwaccel user" >&3
    
    echo "# Starting docker compose..." >&3
    docker compose up -d
    
    echo "# Listing running containers:" >&3
    docker compose ps >&3

    CONTAINER_ID=$(docker compose ps -q seanime)
    echo "# Container ID: $CONTAINER_ID" >&3
    [ -n "$CONTAINER_ID" ]

    echo "# Inspecting container configuration:" >&3
    docker inspect --format='User: {{.Config.User}}' "$CONTAINER_ID" >&3
    docker inspect --format='Image: {{.Config.Image}}' "$CONTAINER_ID" >&3
    docker inspect --format='Devices: {{.HostConfig.Devices}}' "$CONTAINER_ID" >&3
    docker inspect --format='GroupAdd: {{.HostConfig.GroupAdd}}' "$CONTAINER_ID" >&3

    run wait_for_health "$CONTAINER_ID"
    [ "$status" -eq 0 ]
    
    echo "# Tearing down..." >&3
    docker compose down
    echo "# ✓ Test completed successfully" >&3
}

@test "04-hwaccel-cuda: docker compose up and verify health" {
    echo "# ========================================" >&3
    echo "# TEST: 04-hwaccel-cuda (NVIDIA CUDA variant)" >&3
    echo "# ========================================" >&3
    
    cd "$PROJECT_ROOT/examples/04-hwaccel-cuda"
    echo "# Working directory: $(pwd)" >&3
    
    echo "# Cleaning up existing containers..." >&3
    docker compose down || true
    
    echo "# Creating and setting permissions for volume directories..." >&3
    mkdir -p ./seanime-config ./anime ./downloads
    sudo chown -R 1001:1001 ./seanime-config ./anime ./downloads
    echo "# Set ownership to 1001:1001 for cuda user" >&3
    
    echo "# Starting docker compose..." >&3
    docker compose up -d
    
    echo "# Listing running containers:" >&3
    docker compose ps >&3

    CONTAINER_ID=$(docker compose ps -q seanime)
    echo "# Container ID: $CONTAINER_ID" >&3
    [ -n "$CONTAINER_ID" ]

    echo "# Inspecting container configuration:" >&3
    docker inspect --format='User: {{.Config.User}}' "$CONTAINER_ID" >&3
    docker inspect --format='Image: {{.Config.Image}}' "$CONTAINER_ID" >&3
    docker inspect --format='Runtime: {{.HostConfig.Runtime}}' "$CONTAINER_ID" >&3
    docker inspect --format='GroupAdd: {{.HostConfig.GroupAdd}}' "$CONTAINER_ID" >&3

    run wait_for_health "$CONTAINER_ID"
    [ "$status" -eq 0 ]
    
    echo "# Tearing down..." >&3
    docker compose down
    echo "# ✓ Test completed successfully" >&3
}
