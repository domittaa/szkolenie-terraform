terraform {
  required_version = ">= 1.6"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.10"
    }
  }

  backend "gcs" {
    bucket = "pizza-terraform-state-4821"
    prefix = "shared"
  }
}
