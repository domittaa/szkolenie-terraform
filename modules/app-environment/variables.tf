variable "project_id" {
  type        = string
  description = "Environment project, e.g. pizza-dev-4821"
}

variable "region" {
  type    = string
  default = "europe-central2"
}

variable "env" {
  type        = string
  description = "Environment name"

  validation {
    condition     = contains(["dev", "prod"], var.env)
    error_message = "env must be dev or prod."
  }
}

variable "backend_image" {
  type        = string
  description = "Initial backend image, later revisions are deployed by backend CI"
}

variable "frontend_image" {
  type        = string
  description = "Initial frontend image, later revisions are deployed by frontend CI"
}

variable "deployer_service_accounts" {
  type        = map(string)
  description = "GitHub Actions service accounts from envs/shared, keyed by repository (backend, frontend, ...)"
}

variable "db_tier" {
  type        = string
  description = "Cloud SQL tier. db-f1-micro allows only 25 connections"
}

variable "db_high_availability" {
  type    = bool
  default = false
}

variable "db_deletion_protection" {
  type    = bool
  default = true
}

variable "backend_min_instances" {
  type    = number
  default = 0
}

variable "backend_max_instances" {
  type        = number
  description = "Every instance opens up to 7 DB connections (pizza-core pool 5 + overflow 2)"
}

variable "log_level" {
  type    = string
  default = "INFO"
}

variable "promo_codes_enabled" {
  type        = bool
  default     = false
  description = "Backend PROMO_CODES_ENABLED, keep in sync with VITE_PROMO_CODES_ENABLED of the frontend"
}

variable "extra_cors_origins" {
  type        = list(string)
  default     = []
  description = "Origins allowed by the backend in addition to the pizza-frontend URL"
}

variable "alert_email" {
  type = string
}
