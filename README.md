# Wavestone LiteLLM

## 🧩 Overview

This project deploys a **LiteLLM Proxy Server** using Docker Compose, with a PostgreSQL backend for:

- API key management (`/key/generate`)
- Budget and rate-limiting per key
- Authentication and model provider key encryption
- Optional web UI on `/ui`

---

## 🚀 Quickstart (Local Dev)

### 1. 🧱 Prerequisites

- Docker & Docker Compose installed  
- API keys from your LLM providers (e.g., OpenAI, Anthropic)  
- A secure password generator (for salt & master keys)

---

### 2. 📝 Configure Environment

Edit the `.env` file:

```env
LITELLM_SALT_KEY=sk-<random-salt>           # ⚠️ Irreversible: do not change after key creation
LITELLM_MASTER_KEY=sk-<admin-master-key>    # 🔑 Used to generate API tokens
OPENAI_API_KEY=sk-<your-openai-key>
ANTHROPIC_API_KEY=sk-<your-anthropic-key>
```

You can use https://1password.com/password-generator/ to generate secure values.

---

### 3. 📦 Build & Launch

```bash
docker-compose up --build
```

- LiteLLM UI: http://localhost:4000/ui  
- Swagger: http://localhost:4000/docs

---

### 4. 🔐 Generate an API Key

```bash
curl -X POST http://localhost:4000/key/generate \
  -H "Authorization: Bearer sk-<your-master-key>" \
  -H "Content-Type: application/json" \
  -d '{"models": ["gpt-4", "gpt-3.5-turbo"], "duration": "30m", "metadata": {"user": "test@example.com"}}'
```

Expected response:

```json
{
  "key": "sk-generated-key",
  "expires": "2025-07-27T14:05:13.264000+00:00"
}
```

---

### 5. 💬 Use the Proxy

**Python (OpenAI SDK ≥ v1):**

```python
from openai import OpenAI

client = OpenAI(
  api_key="sk-generated-key",
  base_url="http://localhost:4000"
)

response = client.chat.completions.create(
  model="gpt-3.5-turbo",
  messages=[{"role": "user", "content": "Hello from LiteLLM proxy"}]
)

print(response.choices[0].message.content)
```
