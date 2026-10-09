resource "google_pubsub_topic" "order_events" {
  project = var.project_id
  name    = "order-events"
  labels  = local.labels

  message_retention_duration = "86400s"

  depends_on = [google_project_service.this]
}

resource "google_pubsub_topic" "order_events_dlq" {
  project = var.project_id
  name    = "order-events-dlq"
  labels  = local.labels

  depends_on = [google_project_service.this]
}

# Consumed by notification-service (Notifications team, separate repository)
resource "google_pubsub_subscription" "notification_service" {
  project = var.project_id
  name    = "order-events-notification-service"
  topic   = google_pubsub_topic.order_events.id
  labels  = local.labels

  # pizza-core OrderEvent sets the event_type attribute: order.created, order.status_changed, ...
  filter = "hasPrefix(attributes.event_type, \"order.\")"

  ack_deadline_seconds       = 30
  message_retention_duration = "604800s"

  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "600s"
  }

  # TODO(PIZZA-130): grant the Pub/Sub service agent publisher on the DLQ topic and
  # subscriber on this subscription, otherwise dead-lettering silently does not happen
  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.order_events_dlq.id
    max_delivery_attempts = 10
  }
}

resource "google_pubsub_topic_iam_member" "backend_publisher" {
  project = var.project_id
  topic   = google_pubsub_topic.order_events.name
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.backend.email}"
}
