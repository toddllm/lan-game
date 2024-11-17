#!/bin/bash
set -e

VERSION=$1

if [ -z "$VERSION" ]; then
    echo "Usage: ./scripts/rollback.sh <version>"
    exit 1
fi

echo "Rolling back to version $VERSION..."

git checkout "v$VERSION"
./scripts/upgrade.sh

echo "Rollback complete"
