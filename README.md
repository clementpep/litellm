# LiteLLM Deployment on GCP Cloud Run

## 📊 Déploiement Actuel

**Service URL**: https://litellm-d657povewa-ew.a.run.app
**Projet GCP**: `ai-garage-475806`
**Région**: `europe-west1`
**Status**: ✅ Opérationnel (mode stateless, sans base de données)

---

## 🏗️ Architecture

### Ressources GCP déployées

| Ressource | Nom | Configuration | Status | Coût estimé |
|-----------|-----|---------------|--------|-------------|
| **Cloud Run Service** | litellm | 1 vCPU, 1GB RAM, scale-to-zero | ✅ Running | Gratuit + usage |
| **Artifact Registry** | litellm-repo | Docker images | ✅ Active | ~$0.10/GB/mois |
| **Cloud SQL PostgreSQL** | litellm-db | db-f1-micro, 10GB HDD | ✅ Running | ~$8-10/mois |
| **Database** | litellm | PostgreSQL 15 | ✅ Created | Inclus |

**Total estimé**: ~$10-15/mois

---

## 🔑 Configuration Actuelle

### Variables d'environnement
```bash
LITELLM_MODE=PRODUCTION
LITELLM_LOG=ERROR
LITELLM_SALT_KEY=sk-sUEYgScScg7HJ5ocdMc+/mYQpZnkzDuv/lPbc6S71JhKwybUks8iFT1hvq8oLeUH
LITELLM_MASTER_KEY=sk-0m+gLRphHEY8d/Dl38K2A+d1bP5u+OCXJOHnR2o/MvLs4B/EOC+dgGwS2hEJmbQd
```

### Endpoints disponibles

- **API Health**: https://litellm-d657povewa-ew.a.run.app/health (nécessite auth GCP)
- **UI Admin**: https://litellm-d657povewa-ew.a.run.app/ui (nécessite auth GCP)
- **Documentation Swagger**: https://litellm-d657povewa-ew.a.run.app/docs (nécessite auth GCP)
- **API Proxy**: https://litellm-d657povewa-ew.a.run.app/v1/* (nécessite auth GCP)

---

## ⚠️ Limitations Actuelles

### 1. Mode Stateless (Sans Base de Données)
- ❌ Pas de persistance des configurations
- ❌ Pas de gestion multi-utilisateurs
- ❌ Pas de tracking de l'utilisation/consommation
- ❌ Clés API et modèles perdus au redémarrage
- ✅ Serveur fonctionne et répond aux requêtes

### 2. Accès Public Non Configuré
Le service nécessite actuellement une authentification GCP. Pour tester avec auth :

```bash
# Obtenir un token
TOKEN=$(gcloud auth print-identity-token)

# Tester le health check
curl -H "Authorization: Bearer $TOKEN" https://litellm-d657povewa-ew.a.run.app/health
```

Pour le rendre public, un admin du projet doit exécuter :

```bash
gcloud run services add-iam-policy-binding litellm \
  --region=europe-west1 \
  --member=allUsers \
  --role=roles/run.invoker \
  --project=ai-garage-475806
```

Ou via la Console GCP :
1. https://console.cloud.google.com/run/detail/europe-west1/litellm?project=ai-garage-475806
2. Onglet "Sécurité" → "Authentification" → "Autoriser les invocations non authentifiées"

---

## 🚀 Prochaines Étapes Recommandées

### Étape 1 : Activer l'Accès Public

Demander à un admin GCP d'autoriser les accès non authentifiés (voir section ci-dessus).

### Étape 2 : Activer la Base de Données PostgreSQL

**Avantages** :
- ✅ Panel admin complet avec gestion des utilisateurs
- ✅ Persistance des clés API et configurations
- ✅ Tracking détaillé de l'utilisation et des coûts
- ✅ Support MCP Proxy avec authentification

**Problème actuel** :
La connexion Cloud SQL via Prisma nécessite une configuration spécifique qui n'est pas encore résolue.

**Solution alternative recommandée** : Utiliser SQLite pour commencer

```yaml
# Dans config.yaml, remplacer :
database_url: ${DATABASE_URL}

# Par :
database_url: "sqlite:///app/litellm.db"
```

Puis redéployer. Cela activera le panel admin avec une base SQLite locale.

---

## 📝 Fichiers du Projet

```
genai-litellm/
├── Dockerfile              # Image Docker production
├── entrypoint.sh          # Script de démarrage avec migrations
├── config.yaml            # Configuration LiteLLM
├── requirements.txt       # Dépendances Python
├── cloudbuild.yaml        # Configuration Cloud Build
├── .dockerignore          # Fichiers exclus du build
└── README.md              # Cette documentation
```

---

## 🔧 Commandes Utiles

### Déploiement

```bash
# Build de l'image
cd C:\Users\clement.peponnet\Documents\genai-litellm
gcloud builds submit --config cloudbuild.yaml --region=europe-west1

# Déploiement sur Cloud Run (stateless, sans DB)
gcloud run deploy litellm \
  --image=europe-west1-docker.pkg.dev/ai-garage-475806/litellm-repo/litellm:latest \
  --region=europe-west1 \
  --platform=managed \
  --allow-unauthenticated \
  --port=4000 \
  --memory=1Gi \
  --cpu=1 \
  --min-instances=0 \
  --max-instances=3 \
  --timeout=300 \
  --cpu-boost \
  --set-env-vars="LITELLM_MODE=PRODUCTION,LITELLM_LOG=ERROR,LITELLM_SALT_KEY=sk-sUEYgScScg7HJ5ocdMc+/mYQpZnkzDuv/lPbc6S71JhKwybUks8iFT1hvq8oLeUH,LITELLM_MASTER_KEY=sk-0m+gLRphHEY8d/Dl38K2A+d1bP5u+OCXJOHnR2o/MvLs4B/EOC+dgGwS2hEJmbQd"
```

### Monitoring

```bash
# Voir les logs
gcloud run services logs read litellm --region=europe-west1 --limit=50

# Voir les révisions déployées
gcloud run revisions list --service=litellm --region=europe-west1

# Infos sur le service
gcloud run services describe litellm --region=europe-west1
```

### Base de Données

```bash
# Se connecter à Cloud SQL
gcloud sql connect litellm-db --user=litellm --database=litellm

# Vérifier l'état de l'instance
gcloud sql instances describe litellm-db
```

---

## 📚 Documentation

- **LiteLLM Official Docs**: https://docs.litellm.ai/
- **Production Deployment**: https://docs.litellm.ai/docs/proxy/prod
- **Cloud Run Documentation**: https://cloud.google.com/run/docs
- **Cloud SQL with Cloud Run**: https://cloud.google.com/sql/docs/postgres/connect-run

---

## 🐛 Troubleshooting

### Le service ne démarre pas
```bash
# Vérifier les logs de démarrage
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=litellm" \
  --limit=50 --project=ai-garage-475806
```

### Erreur de connexion à la base de données
- Vérifier que Cloud SQL est en état `RUNNABLE` : `gcloud sql instances describe litellm-db`
- Vérifier que `--add-cloudsql-instances` est configuré sur Cloud Run
- Vérifier le format de `DATABASE_URL`

### Panel admin inaccessible
- S'assurer que `ui: true` est dans `config.yaml`
- Tester avec authentification : `curl -H "Authorization: Bearer $(gcloud auth print-identity-token)" <URL>/ui`

---

## ✅ État Actuel

**Opérationnel** :
- ✅ Image Docker construite et déployée
- ✅ Serveur LiteLLM qui répond sur Cloud Run
- ✅ Configuration production selon la doc officielle
- ✅ Base de données PostgreSQL créée (non connectée)

**À faire** :
- ⏳ Activer l'accès public (permissions IAM)
- ⏳ Connecter la base de données OU migrer vers SQLite
- ⏳ Tester le panel admin
- ⏳ Ajouter des clés API pour LLM providers (OpenAI, Anthropic, etc.)
- ⏳ Configurer monitoring/alerting

---

**Dernière mise à jour** : 5 novembre 2025
