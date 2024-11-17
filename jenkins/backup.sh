#!/bin/bash
set -e

BACKUP_DIR="jenkins_backup"
mkdir -p $BACKUP_DIR
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "Creating Jenkins backup..."
docker run --rm \
  --volumes-from $(docker-compose ps -q jenkins) \
  -v $(pwd)/$BACKUP_DIR:/backup \
  alpine \
  tar czf /backup/jenkins_backup_${TIMESTAMP}.tar.gz /var/jenkins_home

echo "Backup created: $BACKUP_DIR/jenkins_backup_${TIMESTAMP}.tar.gz"
