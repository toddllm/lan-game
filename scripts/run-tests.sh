#!/bin/bash
set -e

# Run unit tests
source venv/bin/activate
python -m pytest tests/unit/

# Run E2E tests
npm run test
