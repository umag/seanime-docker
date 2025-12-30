#!/usr/bin/env bats

setup() {
    # Define project root
    PROJECT_ROOT="$(git rev-parse --show-toplevel)"
}

wait_for_health() {
    local service_name="$1"
    local max_retries=60
    local retry=0

    echo "Waiting for $service_name to be healthy..."
    while [ $retry -lt $max_retries ]; do
        local health_status
        health_status=$(docker inspect --format='{{.State.Health.Status}}' "$service_name" 2>/dev/null || echo "not_found")
        
        if [ "$health_status" == "healthy" ]; then
            echo "$service_name is healthy!"
            return 0
        fi

        echo "Retry $retry/$max_retries: Status is $health_status"
        retry=$((retry + 1))
        sleep 2
    done

    echo "Timed out waiting for $service_name"
    docker logs "$service_name"
    return 1
}

@test "01-default: docker compose up and verify health" {
    cd "$PROJECT_ROOT/examples/01-default"
    
    # Clean up any potential leftovers
    docker compose down || true

    # Start
    docker compose up -d

    # Get container name (assuming standard naming or using compose ps)
    # The default example creates a container named "seanime" due to `container_name: seanime` usually?
    # Checking the file `examples/01-default/docker-compose.yml` content would verify this, but let's assume standard compose naming if not.
    # Actually, let's use `docker compose ps -q` to get the ID.
    
    CONTAINER_ID=$(docker compose ps -q seanime)
    [ -n "$CONTAINER_ID" ]

    run wait_for_health "$CONTAINER_ID"
    [ "$status" -eq 0 ]
    
    # Teardown
    docker compose down
}

@test "02-rootless: docker compose up and verify health" {
    cd "$PROJECT_ROOT/examples/02-rootless"
    
    docker compose down || true
    docker compose up -d

    CONTAINER_ID=$(docker compose ps -q seanime)
    [ -n "$CONTAINER_ID" ]

    run wait_for_health "$CONTAINER_ID"
    [ "$status" -eq 0 ]
    
    docker compose down
}
