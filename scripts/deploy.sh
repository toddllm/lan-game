#!/bin/bash
set -e

VERSION=$1

if [ -z "$VERSION" ]; then
    echo "Usage: ./scripts/deploy.sh <version>"
    exit 1
fi

echo "Deploying version $VERSION..."

# Tag the version
git tag -a "v$VERSION" -m "Release version $VERSION"

# Build and deploy with Docker
docker-compose -f docker/docker-compose.prod.yml build
./scripts/upgrade.sh

echo "Deployment complete"
