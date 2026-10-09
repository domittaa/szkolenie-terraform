terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.0"
    }
  }
}

resource "google_cloud_run_v2_service" "this" {
  name                = var.name
  project             = var.project_id
  location            = var.region
  ingress             = "INGRESS_TRAFFIC_ALL"
  labels              = var.labels
  deletion_protection = false

  template {
    service_account = var.service_account_email
    labels          = var.labels

    scaling {
      min_instance_count = var.min_instances
      max_instance_count = var.max_instances
    }

    dynamic "volumes" {
      for_each = length(var.cloud_sql_instances) > 0 ? [1] : []
      content {
        name = "cloudsql"
        cloud_sql_instance {
          instances = var.cloud_sql_instances
        }
      }
    }

    containers {
      image = var.image

      ports {
        container_port = var.container_port
      }

      resources {
        limits = {
          cpu    = var.cpu
          memory = var.memory
        }
        cpu_idle = true
      }

      dynamic "env" {
        for_each = var.env
        content {
          name  = env.key
          value = env.value
        }
      }

      dynamic "env" {
        for_each = var.secret_env
        content {
          name = env.key
          value_source {
            secret_key_ref {
              secret  = env.value.secret
              version = env.value.version
            }
          }
        }
      }

      dynamic "volume_mounts" {
        for_each = length(var.cloud_sql_instances) > 0 ? [1] : []
        content {
          name       = "cloudsql"
          mount_path = "/cloudsql"
        }
      }

      dynamic "startup_probe" {
        for_each = var.startup_probe_path == null ? [] : [var.startup_probe_path]
        content {
          initial_delay_seconds = 2
          period_seconds        = 5
          failure_threshold     = 12
          http_get {
            path = startup_probe.value
          }
        }
      }

      dynamic "liveness_probe" {
        for_each = var.liveness_probe_path == null ? [] : [var.liveness_probe_path]
        content {
          period_seconds    = 30
          failure_threshold = 3
          http_get {
            path = liveness_probe.value
          }
        }
      }
    }
  }

  lifecycle {
    # New images are rolled out by CI (`gcloud run deploy`), Terraform owns the rest of the config
    ignore_changes = [
      template[0].containers[0].image,
      client,
      client_version,
    ]
  }
}

# Authentication is handled by the application (Identity Platform ID tokens)
resource "google_cloud_run_v2_service_iam_member" "public" {
  count = var.allow_unauthenticated ? 1 : 0

  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.this.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
