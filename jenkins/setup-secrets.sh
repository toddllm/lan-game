#!/bin/bash
# jenkins/setup-secrets.sh
set -e

# Create secrets directory
mkdir -p secrets

# Generate random admin password if it doesn't exist
if [ ! -f secrets/jenkins_admin_password.txt ]; then
    openssl rand -base64 32 > secrets/jenkins_admin_password.txt
    echo "Generated new Jenkins admin password"
fi

# Generate random automation password if it doesn't exist
if [ ! -f secrets/automation_password.txt ]; then
    openssl rand -base64 32 > secrets/automation_password.txt
    echo "Generated new automation account password"
fi

# Prompt for game password if it doesn't exist
if [ ! -f secrets/game_password.txt ]; then
    read -sp "Enter game password: " game_password
    echo
    echo "$game_password" > secrets/game_password.txt
    echo "Saved game password"
fi

# Set proper permissions
chmod 600 secrets/*

# Add secrets directory to .gitignore
if [ ! -f .gitignore ]; then
    echo "secrets/" > .gitignore
fi

echo "Secrets have been set up"
echo "Jenkins admin password: $(cat secrets/jenkins_admin_password.txt)"
echo "Automation account password: $(cat secrets/automation_password.txt)"