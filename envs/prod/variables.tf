variable "project_id" {
  type = string
}

variable "region" {
  type    = string
  default = "europe-central2"
}

variable "bootstrap_image" {
  type        = string
  default     = "us-docker.pkg.dev/cloudrun/container/hello"
  description = "Image used only when the Cloud Run services are created"
}

variable "db_tier" {
  type = string
}

variable "db_high_availability" {
  type    = bool
  default = false
}

variable "backend_min_instances" {
  type    = number
  default = 0
}

variable "backend_max_instances" {
  type = number
}

variable "log_level" {
  type    = string
  default = "INFO"
}

variable "promo_codes_enabled" {
  type    = bool
  default = false
}

variable "extra_cors_origins" {
  type    = list(string)
  default = []
}

variable "alert_email" {
  type = string
}
