#!/bin/bash
set -e

echo "=== LiteLLM Production Startup (Stateless Mode) ==="
echo "Mode: No database (stateless)"
echo "Port: 4000"
echo "Config: /app/config.yaml"
echo "Workers: 1"
echo ""
echo "Starting LiteLLM proxy server..."

# Start LiteLLM in stateless mode (no database)
exec litellm --port 4000 --config /app/config.yaml --num_workers 1
