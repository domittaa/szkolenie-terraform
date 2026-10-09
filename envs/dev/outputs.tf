output "backend_url" {
  description = "API_BASE_URL in the dev GitHub environment of the frontend repo"
  value       = module.app.backend_url
}

output "frontend_url" {
  value = module.app.frontend_url
}

output "db_connection_name" {
  value = module.app.db_connection_name
}
