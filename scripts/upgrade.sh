#!/bin/bash
set -e

function check_health() {
    local container=$1
    local max_attempts=30
    local attempt=1

    echo "Checking health of $container..."
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s "http://localhost:5001/health" | grep -q "ok"; then
            echo "$container is healthy"
            return 0
        fi
        echo "Attempt $attempt of $max_attempts..."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    echo "$container failed health check"
    return 1
}

function upgrade_server() {
    local server=$1
    
    echo "Upgrading $server..."
    docker-compose stop $server
    docker-compose up -d --no-deps --build $server
    
    if ! check_health $server; then
        echo "Health check failed for $server. Rolling back..."
        docker-compose stop $server
        docker-compose up -d --no-deps server-backup
        exit 1
    fi
}

# Create backup
docker-compose up -d --no-deps --name server-backup server1

# Rolling upgrade
upgrade_server server2
upgrade_server server1

# Cleanup
docker-compose rm -f server-backup
