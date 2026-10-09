output "workload_identity_provider" {
  description = "Used as workload_identity_provider in the GitHub workflows of all repositories"
  value       = google_iam_workload_identity_pool_provider.github.name
}

output "deployer_service_accounts" {
  description = "Read by envs/dev and envs/prod through terraform_remote_state"
  value       = { for key, sa in google_service_account.ci : key => sa.email }
}

output "containers_repository_url" {
  value = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.containers.repository_id}"
}

output "python_index_url" {
  value = "https://${var.region}-python.pkg.dev/${var.project_id}/${google_artifact_registry_repository.python_libs.repository_id}/simple/"
}
