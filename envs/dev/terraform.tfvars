project_id = "pizza-dev-4821"
region     = "europe-central2"

db_tier              = "db-f1-micro"
db_high_availability = false

# db-f1-micro allows 25 connections: 2 instances * (5 + 2) = 14, plus the migration job
backend_min_instances = 0
backend_max_instances = 2

log_level           = "DEBUG"
promo_codes_enabled = true

# local frontend (Vite dev server) against the dev API
extra_cors_origins = ["http://localhost:5173"]

alert_email = "pizza-alerts-dev@example.com"
