#!/bin/bash
set -e

if [ -z "$1" ]; then
    echo "Usage: ./restore.sh <backup_file>"
    exit 1
fi

BACKUP_FILE=$1

# Stop Jenkins
docker-compose down

# Clear existing volume
docker volume rm jenkins_home
docker volume create jenkins_home

# Restore from backup
echo "Restoring Jenkins from backup..."
docker run --rm \
  -v jenkins_home:/var/jenkins_home \
  -v $(pwd)/$BACKUP_FILE:/backup.tar.gz \
  alpine \
  tar xzf /backup.tar.gz

# Restart Jenkins
docker-compose up -d

echo "Restore completed. Jenkins is restarting..."
