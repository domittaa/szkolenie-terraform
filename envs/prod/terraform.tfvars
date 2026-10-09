project_id = "pizza-prod-4821"
region     = "europe-central2"

db_tier              = "db-custom-2-7680"
db_high_availability = true

# PIZZA-120: keep one warm instance to avoid cold starts during the lunch peak
backend_min_instances = 1
backend_max_instances = 10

log_level = "INFO"

# PIZZA-91: enable after the marketing sign-off
promo_codes_enabled = false

extra_cors_origins = []

alert_email = "pizza-alerts@example.com"
