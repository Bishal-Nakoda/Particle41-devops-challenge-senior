terraform {
  required_version = ">= 0.12"
  backend "gcs" {
    bucket = var.state_files_bucket_id
    prefix = "state-files"
  }
}

provider "google" {
  version = ">= 5.12.0, < 6.0.0"
  project = var.project_id
  region  = var.region
}

