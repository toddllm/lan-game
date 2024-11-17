#!/bin/bash
# scripts/server-control.sh
set -e

function find_server() {
    pgrep -f "python.*server.py" || echo ""
}

function stop_server() {
    local pid=$(find_server)
    if [ ! -z "$pid" ]; then
        echo "Stopping server (PID: $pid)..."
        kill $pid
        # Wait for it to actually stop
        for i in {1..5}; do
            if ! ps -p $pid > /dev/null; then
                echo "Server stopped"
                return 0
            fi
            sleep 1
        done
        # Force kill if still running
        echo "Force stopping server..."
        kill -9 $pid 2>/dev/null || true
    else
        echo "No running server found"
    fi
}

function restart_server() {
    stop_server
    echo "Starting new server..."
    ./scripts/run-dev.sh
}

case "$1" in
    "stop")
        stop_server
        ;;
    "restart")
        restart_server
        ;;
    *)
        echo "Usage: $0 {stop|restart}"
        exit 1
        ;;
esac