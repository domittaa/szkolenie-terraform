variable "name" {
  type = string
}

variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "image" {
  type        = string
  description = "Initial image. CI deploys new revisions afterwards, image changes are ignored by Terraform"
}

variable "service_account_email" {
  type = string
}

variable "container_port" {
  type        = number
  default     = 8080
  description = "Port the container listens on (Cloud Run passes it as $PORT)"
}

variable "env" {
  type        = map(string)
  default     = {}
  description = "Plain environment variables"
}

variable "secret_env" {
  type = map(object({
    secret  = string
    version = optional(string, "latest")
  }))
  default     = {}
  description = "Environment variables read from Secret Manager"
}

variable "cloud_sql_instances" {
  type        = list(string)
  default     = []
  description = "Cloud SQL connection names, mounted as unix sockets under /cloudsql"
}

variable "min_instances" {
  type    = number
  default = 0
}

variable "max_instances" {
  type    = number
  default = 2
}

variable "cpu" {
  type    = string
  default = "1"
}

variable "memory" {
  type    = string
  default = "512Mi"
}

variable "startup_probe_path" {
  type    = string
  default = null
}

variable "liveness_probe_path" {
  type    = string
  default = null
}

variable "allow_unauthenticated" {
  type    = bool
  default = true
}

variable "labels" {
  type    = map(string)
  default = {}
}
