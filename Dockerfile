# Dockerfile to build a LiteLLM proxy server with proxy support
FROM python:3.12-slim

# Set working directory
WORKDIR /app

# Install system dependencies (optional: add git if using local clones)
RUN apt-get update && apt-get install -y build-essential && rm -rf /var/lib/apt/lists/*

# Copy and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the full project (if needed for customization)
COPY . .

# Expose the default LiteLLM proxy port
EXPOSE 4000

# Start the LiteLLM proxy with a default model (can be overridden in docker-compose)
CMD ["litellm", "--model", "openai/gpt-4o"]