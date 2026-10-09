locals {
  # Must match backend app/settings.py (pydantic-settings, names are case-insensitive)
  backend_env = {
    APP_ENV                     = var.env
    LOG_LEVEL                   = var.log_level
    GCP_PROJECT_ID              = var.project_id
    DB_INSTANCE_CONNECTION_NAME = google_sql_database_instance.main.connection_name
    DB_NAME                     = google_sql_database.app.name
    DB_USER                     = google_sql_user.app.name
    AUTH_ISSUER                 = "https://securetoken.google.com/${var.project_id}"
    AUTH_AUDIENCE               = var.project_id
    ORDERS_TOPIC                = google_pubsub_topic.order_events.name
    CORS_ALLOWED_ORIGINS        = join(",", concat([module.frontend.uri], var.extra_cors_origins))
    PROMO_CODES_ENABLED         = tostring(var.promo_codes_enabled)
  }

  backend_secret_env = {
    DB_PASSWORD = { secret = google_secret_manager_secret.db_password.secret_id }
  }
}

module "frontend" {
  source = "../cloud-run-service"

  name                  = "pizza-frontend"
  project_id            = var.project_id
  region                = var.region
  image                 = var.frontend_image
  service_account_email = google_service_account.frontend.email
  min_instances         = 0
  max_instances         = 3
  memory                = "256Mi"
  liveness_probe_path   = "/healthz"
  labels                = local.labels

  depends_on = [google_project_service.this]
}

module "backend" {
  source = "../cloud-run-service"

  name                  = "pizza-backend"
  project_id            = var.project_id
  region                = var.region
  image                 = var.backend_image
  service_account_email = google_service_account.backend.email
  env                   = local.backend_env
  secret_env            = local.backend_secret_env
  cloud_sql_instances   = [google_sql_database_instance.main.connection_name]
  min_instances         = var.backend_min_instances
  max_instances         = var.backend_max_instances
  memory                = "512Mi"
  startup_probe_path    = "/readyz"
  liveness_probe_path   = "/healthz"
  labels                = local.labels

  depends_on = [
    google_project_service.this,
    google_secret_manager_secret_version.db_password,
    google_secret_manager_secret_iam_member.backend_db_password,
  ]
}

# Alembic migrations, executed by backend CI before every deploy:
#   gcloud run jobs execute pizza-backend-migrate --wait
resource "google_cloud_run_v2_job" "backend_migrate" {
  project             = var.project_id
  name                = "pizza-backend-migrate"
  location            = var.region
  labels              = local.labels
  deletion_protection = false

  template {
    task_count = 1

    template {
      service_account = google_service_account.backend.email
      max_retries     = 0
      timeout         = "600s"

      volumes {
        name = "cloudsql"
        cloud_sql_instance {
          instances = [google_sql_database_instance.main.connection_name]
        }
      }

      containers {
        image   = var.backend_image
        command = ["alembic"]
        args    = ["upgrade", "head"]

        dynamic "env" {
          for_each = local.backend_env
          content {
            name  = env.key
            value = env.value
          }
        }

        env {
          name = "DB_PASSWORD"
          value_source {
            secret_key_ref {
              secret  = google_secret_manager_secret.db_password.secret_id
              version = "latest"
            }
          }
        }

        volume_mounts {
          name       = "cloudsql"
          mount_path = "/cloudsql"
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      template[0].template[0].containers[0].image,
      client,
      client_version,
    ]
  }

  depends_on = [
    google_project_service.this,
    google_secret_manager_secret_iam_member.backend_db_password,
  ]
}
