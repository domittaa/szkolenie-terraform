provider "google" {
  project = var.project_id
  region  = var.region
}

data "terraform_remote_state" "shared" {
  backend = "gcs"

  config = {
    bucket = "pizza-terraform-state-4821"
    prefix = "shared"
  }
}

module "app" {
  source = "../../modules/app-environment"

  project_id = var.project_id
  region     = var.region
  env        = "dev"

  # placeholder images for the first apply, backend/frontend CI deploys the real ones
  backend_image  = var.bootstrap_image
  frontend_image = var.bootstrap_image

  deployer_service_accounts = data.terraform_remote_state.shared.outputs.deployer_service_accounts

  db_tier                = var.db_tier
  db_high_availability   = var.db_high_availability
  db_deletion_protection = false

  backend_min_instances = var.backend_min_instances
  backend_max_instances = var.backend_max_instances

  log_level           = var.log_level
  promo_codes_enabled = var.promo_codes_enabled
  extra_cors_origins  = var.extra_cors_origins
  alert_email         = var.alert_email
}
