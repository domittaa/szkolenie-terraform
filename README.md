# gcp (Pizza Platform infrastructure)

Terraform for everything the Pizza Platform runs on in Google Cloud (region `europe-central2`, Warsaw).

## Layout

| Path | Project | What |
|---|---|---|
| `envs/shared` | `pizza-shared-4821` | Artifact Registry (`containers`, `python-libs`), GitHub Workload Identity Federation, CI service accounts |
| `envs/dev` | `pizza-dev-4821` | dev, applied automatically on merge to `main` |
| `envs/prod` | `pizza-prod-4821` | prod, applied manually with an approval |
| `modules/app-environment` | – | everything one environment needs: Cloud Run, Cloud SQL, Pub/Sub, secrets, monitoring |
| `modules/cloud-run-service` | – | reusable Cloud Run v2 service |

## Architecture

```
                         ┌─────────────────────┐
  browser ──────────────►│ pizza-frontend      │  Cloud Run, nginx :8080
     │                   └─────────────────────┘
     │ /api/v1/* + ID token
     ▼
  ┌─────────────────────┐   publish    ┌──────────────────────┐
  │ pizza-backend       │─────────────►│ Pub/Sub order-events │──► notification-service
  │ Cloud Run, FastAPI  │              └──────────────────────┘
  └──────────┬──────────┘
             │ /cloudsql unix socket          Secret Manager: db-password
             ▼                                Identity Platform: ID tokens (JWKS)
  ┌─────────────────────┐
  │ Cloud SQL Postgres  │◄── pizza-backend-migrate (Cloud Run job, alembic)
  └─────────────────────┘
```

## Contracts with the other repositories

| What | Here | Other repository |
|---|---|---|
| Backend env vars | `modules/app-environment/services.tf` → `local.backend_env` | backend `app/settings.py` |
| Health endpoints `/healthz`, `/readyz` | probes in `services.tf`, uptime check in `monitoring.tf` | backend `app/api/routes/health.py`, frontend `nginx.conf` |
| Container port 8080 | `modules/cloud-run-service` (`container_port`) | backend `Dockerfile`, frontend `nginx.conf` |
| CORS | `CORS_ALLOWED_ORIGINS` = frontend URL + `extra_cors_origins` | frontend Vite dev server on port 5173 |
| Feature flags | `promo_codes_enabled` in tfvars | frontend `VITE_PROMO_CODES_ENABLED` (GitHub environment) |
| Pub/Sub topic and the filter on the `event_type` attribute | `messaging.tf` | core-library `pizza_core/events.py` |
| DB connections: `db_tier` vs `backend_max_instances` | tfvars | core-library `pizza_core/db.py` (pool 5 + overflow 2 per instance) |
| Migration job `pizza-backend-migrate` | `services.tf` | backend `.github/workflows/ci.yml` |
| WIF provider, CI service accounts, Artifact Registry repositories | `envs/shared` | `.github/workflows/*` in backend, frontend, core-library |
| Backend URL | `terraform output backend_url` | frontend GitHub environment variable `API_BASE_URL` |

## Usage

```bash
cd envs/dev
terraform init
terraform plan
```

Bootstrap of a new environment (one-off, see Confluence: PIZZA / Runbook: New environment):

1. Create the projects and the state bucket `pizza-terraform-state-4821`.
2. Grant `gh-terraform` `roles/editor`, `roles/resourcemanager.projectIamAdmin`,
   `roles/iam.serviceAccountAdmin` and `roles/secretmanager.admin` in the environment projects.
3. Apply `envs/shared`, then `envs/dev`, then `envs/prod`. Cloud Run starts with the `hello` image,
   backend and frontend CI deploy the real ones.

## Workflow

- Every change goes through a PR, CI runs `fmt`, `validate` and `plan` for all environments.
- Merge to `main` applies `envs/dev`. `envs/shared` and `envs/prod` are applied with the `terraform`
  workflow (`workflow_dispatch`), prod requires an approval.

## Links

- Jira: project **PIZZA**, component `infra`
- Confluence: PIZZA → *Infrastructure Overview*, *Runbook: Deployments*, *Runbook: New environment*
