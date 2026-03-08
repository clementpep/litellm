# LiteLLM — Technical Documentation

> LiteLLM Proxy deployed on GCP, acting as a unified LLM gateway for all Wavestone AI applications (WaveGPT, WaveTranslate, Smart Visit Debrief, etc.). Routes requests to Google Gemini models.

**Status:** ✅ Operational (GKE — stateless mode)
**Admin UI:** <http://35.205.93.210/ui/>
**API Endpoint:** <http://35.205.93.210>
**Codebase:** <https://gitlab.wavestone-app.com/produits-mldl/ai-lab/genai-litellm>
**Next owners:** Hemendra UTCHANAH & Alban DANET

---

## Overview

LiteLLM Proxy is an open-source LLM gateway that provides a unified OpenAI-compatible API for multiple model providers. Wavestone's deployment routes requests to Google Gemini models and is used as the default LLM backend by WaveGPT, WaveTranslate, and Smart Visit Debrief.

The proxy runs in **stateless mode** (no database persistence): model configurations survive pod restarts only via `config.yaml` / ConfigMap.

### Tech Stack

| Component | Technology |
|-----------|------------|
| Proxy | Python — LiteLLM |
| LLM models | Google Gemini 2.5 (Flash, Flash Lite, Pro) |
| Infrastructure | GKE (`librechat-cluster`, europe-west1-b) |
| Namespace | `litellm` |
| Image registry | Artifact Registry (`wavestone-ai-librechat`) |
| CI/CD | Cloud Build + `cloudbuild.yaml` |

---

## Architecture

```
Wavestone Apps (WaveGPT, WaveTranslate, Smart Visit Debrief)
                        ↓
              GCP Load Balancer (35.205.93.210:80)
                        ↓
         LiteLLM Service (ClusterIP 34.118.232.196:4000)
                        ↓
              LiteLLM Pod (1 replica, port 4000)
                        ↓
                 Google Gemini API
```

---

## GCP Infrastructure

| Resource | Value |
|----------|-------|
| **GCP Project** | `wavestone-ai-librechat` |
| **GKE Cluster** | `librechat-cluster` (europe-west1-b) |
| **Kubernetes Namespace** | `litellm` |
| **External IP** | `35.205.93.210` (LoadBalancer) |
| **Artifact Registry** | `europe-west1-docker.pkg.dev/wavestone-ai-librechat/litellm-repo/litellm` |
| **ConfigMap** | `litellm-config` (mounts `config.yaml`) |
| **Secret** | `litellm-secrets` (master key, salt key) |

**Pod resources:**

- CPU: 250m request / 1000m limit
- RAM: 512Mi request / 2Gi limit
- Workers: 1

**Cost estimate:** ~$25–30/month (LoadBalancer + compute, stateless mode)

---

## Endpoints

| Endpoint | URL | Auth |
|----------|-----|------|
| Admin UI | <http://35.205.93.210/ui> | Master key |
| API Proxy | <http://35.205.93.210/v1/*> | Master key |
| Swagger Docs | <http://35.205.93.210/docs> | Master key |
| Health check | <http://35.205.93.210/health> | Master key |

---

## Environment Variables

| Variable | Description |
|----------|-------------|
| `LITELLM_MODE` | Deployment mode (`PRODUCTION`) |
| `LITELLM_LOG` | Log level (`INFO`) |
| `LITELLM_MASTER_KEY` | Master API key (stored in k8s Secret) |
| `LITELLM_SALT_KEY` | Encryption salt (stored in k8s Secret) |

Secrets are stored in the Kubernetes Secret `litellm-secrets`.

---

## Model Configuration (`config.yaml`)

Models are configured via `config.yaml` (mounted as a ConfigMap). In stateless mode, all model definitions must live there — UI-added models are lost on pod restart.

Current configuration exposes an empty `model_list` (models added via Admin UI are lost on restart). To persist models, update the ConfigMap:

```yaml
model_list:
  - model_name: gemini-2.5-flash
    litellm_params:
      model: gemini/gemini-2.5-flash
      api_key: ${GOOGLE_API_KEY}

  - model_name: gemini-2.5-pro
    litellm_params:
      model: gemini/gemini-2.5-pro
      api_key: ${GOOGLE_API_KEY}

  - model_name: gemini-2.5-flash-lite
    litellm_params:
      model: gemini/gemini-2.5-flash-lite
      api_key: ${GOOGLE_API_KEY}
```

Then apply and restart:

```bash
kubectl create configmap litellm-config \
  --from-file=config.yaml=config.yaml \
  --namespace litellm \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl rollout restart deployment/litellm -n litellm
```

---

## Deployment (CI/CD)

The pipeline builds the Docker image via **Cloud Build** and pushes it to Artifact Registry. Kubernetes deployment is manual.

**Build image:**

```bash
# From genai-litellm/
gcloud builds submit --config cloudbuild.yaml --region=europe-west1
```

**Deploy to GKE (manual):**

```bash
kubectl set image deployment/litellm \
  litellm=europe-west1-docker.pkg.dev/wavestone-ai-librechat/litellm-repo/litellm:latest \
  -n litellm

kubectl rollout status deployment/litellm -n litellm
```

---

## Repository Structure

```
genai-litellm/
├── Dockerfile              # Production Docker image
├── entrypoint.sh           # Startup script
├── config.yaml             # LiteLLM configuration
├── requirements.txt        # Python dependencies
├── cloudbuild.yaml         # Cloud Build pipeline (build only)
├── k8s/                    # Kubernetes manifests
│   ├── namespace.yaml
│   ├── litellm-deployment.yaml
│   ├── litellm-service.yaml
│   ├── litellm-configmap.yaml
│   └── postgres-statefulset.yaml  # Unused (database not connected)
└── README.md               # Deployment documentation
```

---

## Common Operations

### Check pod status

```bash
kubectl get pods -n litellm
kubectl get svc -n litellm
```

### View logs

```bash
kubectl logs -f deployment/litellm -n litellm
```

### Restart the pod

```bash
kubectl rollout restart deployment/litellm -n litellm
```

### Scale (stateless mode supports horizontal scaling)

```bash
kubectl scale deployment litellm -n litellm --replicas=2
```

### Update configuration

```bash
kubectl edit configmap litellm-config -n litellm
kubectl rollout restart deployment/litellm -n litellm
```

---

## Testing the API

```bash
# Get master key from secret
MASTER_KEY=$(kubectl get secret litellm-secrets -n litellm \
  -o jsonpath='{.data.LITELLM_MASTER_KEY}' | base64 -d)

# Health check
curl -H "Authorization: Bearer $MASTER_KEY" http://35.205.93.210/health

# List models
curl -H "Authorization: Bearer $MASTER_KEY" http://35.205.93.210/v1/models

# Chat completion
curl -X POST http://35.205.93.210/v1/chat/completions \
  -H "Authorization: Bearer $MASTER_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model": "gemini-2.5-flash", "messages": [{"role": "user", "content": "Hello"}]}'
```

---

## Known Limitations

- **Stateless mode**: no database persistence — API keys, model configs, and usage stats are lost on pod restart
- **No HTTPS**: Admin UI and API accessible over HTTP only (no TLS on the LoadBalancer)
- **No user management**: master key is shared across all applications
- **PostgreSQL StatefulSet deployed but not connected** (Prisma migration issue pending)

## Recommended Next Steps

1. Connect the PostgreSQL database (fix Prisma migration) or switch to SQLite for persistence
2. Configure HTTPS with a proper domain name
3. Set up per-application virtual keys in the Admin UI
4. Configure usage tracking and alerting

---

## Troubleshooting

### Pod not starting

```bash
kubectl describe pod -l app=litellm -n litellm
kubectl logs -l app=litellm -n litellm --tail=100
```

### Cannot access Admin UI

```bash
# Verify the LoadBalancer has an external IP
kubectl get svc litellm-external -n litellm

# Test connectivity
curl http://35.205.93.210/
```

### Configuration not applied after ConfigMap update

```bash
# Verify the ConfigMap content
kubectl get configmap litellm-config -n litellm -o yaml

# Force restart
kubectl rollout restart deployment/litellm -n litellm
kubectl get pods -n litellm -w
```

---

## Reference Documentation

- [LiteLLM Official Docs](https://docs.litellm.ai/)
- [LiteLLM Production Deployment](https://docs.litellm.ai/docs/proxy/prod)
- [Cloud Run Documentation](https://cloud.google.com/run/docs)

---

*Last updated: March 2026*
