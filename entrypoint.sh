#!/bin/bash
set -e

echo "=== LiteLLM Production Startup ==="
echo "Database: SQLite at /app/litellm.db"
echo "Starting LiteLLM proxy server..."
echo "Port: 4000"
echo "Config: /app/config.yaml"
echo "Workers: $(nproc)"

# Start LiteLLM with production settings
# Prisma migrations will run automatically on startup
exec litellm --port 4000 --config /app/config.yaml --num_workers $(nproc)
