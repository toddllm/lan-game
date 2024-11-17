#!/bin/bash
set -e

echo "Setting up development environment..."

# Create virtual environment if it doesn not exist
if [ ! -d "venv" ]; then
    python3 -m venv venv
    echo "Created virtual environment"
fi

# Activate virtual environment
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Initialize database
python scripts/init_db.py

echo "Development environment setup complete"
echo "Run 'source venv/bin/activate' to activate the virtual environment"
