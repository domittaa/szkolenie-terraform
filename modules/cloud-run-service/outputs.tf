output "name" {
  value = google_cloud_run_v2_service.this.name
}

output "uri" {
  description = "https://<name>-<hash>.<region>.run.app"
  value       = google_cloud_run_v2_service.this.uri
}
