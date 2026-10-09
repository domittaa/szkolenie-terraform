resource "google_monitoring_notification_channel" "email" {
  project      = var.project_id
  display_name = "Pizza Platform on-call (${var.env})"
  type         = "email"

  labels = {
    email_address = var.alert_email
  }
}

# Uptime check against the backend liveness endpoint (backend app/api/routes/health.py)
resource "google_monitoring_uptime_check_config" "backend" {
  project      = var.project_id
  display_name = "pizza-backend /healthz (${var.env})"
  timeout      = "10s"
  period       = "60s"

  http_check {
    path         = "/healthz"
    port         = 443
    use_ssl      = true
    validate_ssl = true
  }

  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = var.project_id
      host       = trimprefix(module.backend.uri, "https://")
    }
  }
}

resource "google_monitoring_alert_policy" "backend_down" {
  project      = var.project_id
  display_name = "pizza-backend is down (${var.env})"
  combiner     = "OR"

  conditions {
    display_name = "Uptime check is failing"

    condition_threshold {
      filter          = "metric.type=\"monitoring.googleapis.com/uptime_check/check_passed\" AND resource.type=\"uptime_url\" AND metric.label.check_id=\"${google_monitoring_uptime_check_config.backend.uptime_check_id}\""
      comparison      = "COMPARISON_GT"
      threshold_value = 1
      duration        = "120s"

      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_NEXT_OLDER"
        cross_series_reducer = "REDUCE_COUNT_FALSE"
        group_by_fields      = ["resource.label.host"]
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.id]
}

resource "google_monitoring_alert_policy" "backend_5xx" {
  project      = var.project_id
  display_name = "pizza-backend 5xx responses (${var.env})"
  combiner     = "OR"

  conditions {
    display_name = "More than 5 responses with 5xx per minute"

    condition_threshold {
      filter          = "metric.type=\"run.googleapis.com/request_count\" AND resource.type=\"cloud_run_revision\" AND resource.label.service_name=\"${module.backend.name}\" AND metric.label.response_code_class=\"5xx\""
      comparison      = "COMPARISON_GT"
      threshold_value = 5
      duration        = "300s"

      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_DELTA"
        cross_series_reducer = "REDUCE_SUM"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.id]
}
