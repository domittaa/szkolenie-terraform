provider "google" {
  project = var.project_id
  region  = var.region
}

locals {
  services = [
    "artifactregistry.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "sts.googleapis.com",
    "cloudresourcemanager.googleapis.com",
  ]

  # GitHub repository -> service account used by its workflows
  ci_identities = {
    backend      = { repository = var.github_repositories.backend, account_id = "gh-backend-deployer" }
    frontend     = { repository = var.github_repositories.frontend, account_id = "gh-frontend-deployer" }
    core_library = { repository = var.github_repositories.core_library, account_id = "gh-core-library-publisher" }
    terraform    = { repository = var.github_repositories.gcp, account_id = "gh-terraform" }
  }
}

resource "google_project_service" "this" {
  for_each = toset(local.services)

  service            = each.value
  disable_on_destroy = false
}

# --- Artifact Registry --------------------------------------------------------

resource "google_artifact_registry_repository" "containers" {
  repository_id = "containers"
  location      = var.region
  format        = "DOCKER"
  description   = "Container images: backend, frontend"

  cleanup_policies {
    id     = "keep-last-30"
    action = "KEEP"
    most_recent_versions {
      keep_count = 30
    }
  }

  cleanup_policies {
    id     = "delete-older-than-30-days"
    action = "DELETE"
    condition {
      older_than = "2592000s"
    }
  }

  depends_on = [google_project_service.this]
}

resource "google_artifact_registry_repository" "python_libs" {
  repository_id = "python-libs"
  location      = var.region
  format        = "PYTHON"
  description   = "Internal Python packages (pizza-core from the core-library repo)"

  depends_on = [google_project_service.this]
}

# --- GitHub Actions: Workload Identity Federation -----------------------------

resource "google_iam_workload_identity_pool" "github" {
  workload_identity_pool_id = "github"
  display_name              = "GitHub Actions"

  depends_on = [google_project_service.this]
}

resource "google_iam_workload_identity_pool_provider" "github" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github"
  display_name                       = "GitHub OIDC"

  attribute_mapping = {
    "google.subject"             = "assertion.sub"
    "attribute.repository"       = "assertion.repository"
    "attribute.repository_owner" = "assertion.repository_owner"
    "attribute.ref"              = "assertion.ref"
  }
  attribute_condition = "assertion.repository_owner == \"${var.github_owner}\""

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account" "ci" {
  for_each = local.ci_identities

  account_id   = each.value.account_id
  display_name = "GitHub Actions: ${var.github_owner}/${each.value.repository}"
}

resource "google_service_account_iam_member" "ci_workload_identity" {
  for_each = local.ci_identities

  service_account_id = google_service_account.ci[each.key].name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${var.github_owner}/${each.value.repository}"
}

# backend and frontend CI push images
resource "google_artifact_registry_repository_iam_member" "containers_writer" {
  for_each = toset(["backend", "frontend"])

  location   = google_artifact_registry_repository.containers.location
  repository = google_artifact_registry_repository.containers.name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${google_service_account.ci[each.key].email}"
}

# Cloud Run service agents of the dev/prod projects pull images from this registry
resource "google_artifact_registry_repository_iam_member" "containers_reader" {
  for_each = var.runtime_project_numbers

  location   = google_artifact_registry_repository.containers.location
  repository = google_artifact_registry_repository.containers.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:service-${each.value}@serverless-robot-prod.iam.gserviceaccount.com"
}

# core-library CI publishes pizza-core
resource "google_artifact_registry_repository_iam_member" "python_libs_writer" {
  location   = google_artifact_registry_repository.python_libs.location
  repository = google_artifact_registry_repository.python_libs.name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${google_service_account.ci["core_library"].email}"
}

# backend CI installs pizza-core (tests and docker build)
resource "google_artifact_registry_repository_iam_member" "python_libs_reader" {
  location   = google_artifact_registry_repository.python_libs.location
  repository = google_artifact_registry_repository.python_libs.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${google_service_account.ci["backend"].email}"
}

# Note: gh-terraform gets its roles in the dev/prod projects during bootstrap (see README).
