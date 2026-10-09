# --- Runtime service accounts -------------------------------------------------

resource "google_service_account" "backend" {
  project      = var.project_id
  account_id   = "pizza-backend"
  display_name = "pizza-backend (Cloud Run runtime)"
}

resource "google_service_account" "frontend" {
  project      = var.project_id
  account_id   = "pizza-frontend"
  display_name = "pizza-frontend (Cloud Run runtime)"
}

resource "google_project_iam_member" "backend" {
  for_each = toset([
    "roles/cloudsql.client",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/cloudtrace.agent",
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.backend.email}"
}

# Pub/Sub publisher and Secret Manager accessor are granted on the resources themselves,
# see messaging.tf and database.tf.

# --- GitHub Actions deployers (created in envs/shared) ------------------------

resource "google_project_iam_member" "deployer_run_developer" {
  for_each = toset(["backend", "frontend"])

  project = var.project_id
  role    = "roles/run.developer"
  member  = "serviceAccount:${var.deployer_service_accounts[each.key]}"
}

# Deploying a revision requires actAs on the runtime service account
resource "google_service_account_iam_member" "backend_deployer_act_as" {
  service_account_id = google_service_account.backend.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${var.deployer_service_accounts["backend"]}"
}

resource "google_service_account_iam_member" "frontend_deployer_act_as" {
  service_account_id = google_service_account.frontend.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${var.deployer_service_accounts["frontend"]}"
}
