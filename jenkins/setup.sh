#!/bin/bash
# setup.sh
set -e

# Create docker-compose.yml
cat > docker-compose.yml << 'EOL'
version: '3.8'

services:
  jenkins:
    image: jenkins/jenkins:lts
    privileged: true
    user: root
    ports:
      - "8080:8080"
      - "50000:50000"
    volumes:
      - jenkins_home:/var/jenkins_home
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - JAVA_OPTS=-Djenkins.install.runSetupWizard=true
    restart: unless-stopped
    networks:
      - jenkins_net

volumes:
  jenkins_home:
    external: true

networks:
  jenkins_net:
    driver: bridge
EOL

# Create backup script
cat > backup.sh << 'EOL'
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
EOL

# Create restore script
cat > restore.sh << 'EOL'
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
EOL

# Make scripts executable
chmod +x backup.sh restore.sh

# Create the docker volume for Jenkins
echo "Creating Jenkins volume..."
docker volume create jenkins_home

# Start Jenkins
echo "Starting Jenkins..."
docker-compose up -d

# Wait for Jenkins to start
echo "Waiting for Jenkins to start..."
until $(curl --output /dev/null --silent --head --fail http://localhost:8080); do
    printf '.'
    sleep 5
done

# Get the initial admin password
echo -e "\nJenkins is up! Here's your initial admin password:"
docker-compose exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword

echo -e "\nJenkins is running at http://localhost:8080"
echo "Use the password above to complete the setup"
echo "Install suggested plugins when prompted"

# Print volume location for backup purposes
echo -e "\nJenkins volume information:"
docker volume inspect jenkins_home