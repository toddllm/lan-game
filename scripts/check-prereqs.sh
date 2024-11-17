#!/bin/bash
set -e

# Check Python version
python_version=$(python3 --version 2>&1 | awk '{print $2}')
required_python="3.8.0"

if [ "$(printf '%s\n' "$required_python" "$python_version" | sort -V | head -n1)" = "$required_python" ]; then 
    echo "Python version OK: $python_version"
else
    echo "Error: Python version must be at least $required_python"
    exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "Error: Docker Compose is not installed"
    exit 1
fi

# Check if Node.js is installed (for Playwright tests)
if ! command -v node &> /dev/null; then
    echo "Error: Node.js is not installed"
    exit 1
fi

# Check if required ports are available
if lsof -Pi :5001 -sTCP:LISTEN -t >/dev/null ; then
    echo "Error: Port 5001 is already in use"
    exit 1
fi

echo "All prerequisites checked successfully"
