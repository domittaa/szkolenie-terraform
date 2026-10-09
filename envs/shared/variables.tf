variable "project_id" {
  type        = string
  description = "Shared project with Artifact Registry and GitHub Workload Identity Federation"
}

variable "region" {
  type    = string
  default = "europe-central2"
}

variable "github_owner" {
  type        = string
  description = "GitHub organization (or user) that owns the repositories"
}

variable "github_repositories" {
  type = object({
    backend      = string
    frontend     = string
    core_library = string
    gcp          = string
  })
  description = "GitHub repository names, without the owner"
}

variable "runtime_project_numbers" {
  type        = map(string)
  description = "Project numbers of the environment projects, their Cloud Run service agents pull images"
}
