# LiteLLM Production Docker Image
# Based on: https://docs.litellm.ai/docs/proxy/prod

FROM python:3.12-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Generate Prisma binaries for database ORM
RUN prisma generate --schema=/usr/local/lib/python3.12/site-packages/litellm/proxy/schema.prisma

# Copy configuration file and entrypoint script
COPY config.yaml .
COPY entrypoint.sh .
RUN chmod +x /app/entrypoint.sh

# Expose LiteLLM proxy port
EXPOSE 4000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD curl -f http://localhost:4000/health/readiness || exit 1

# Use entrypoint script to handle database migrations and startup
ENTRYPOINT ["/app/entrypoint.sh"]
