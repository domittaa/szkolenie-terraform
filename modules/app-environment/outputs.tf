output "backend_url" {
  value = module.backend.uri
}

output "frontend_url" {
  value = module.frontend.uri
}

output "db_connection_name" {
  value = google_sql_database_instance.main.connection_name
}

output "orders_topic" {
  value = google_pubsub_topic.order_events.name
}

output "backend_service_account" {
  value = google_service_account.backend.email
}
