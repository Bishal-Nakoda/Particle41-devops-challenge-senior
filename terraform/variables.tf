variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "Region for Cloud Run and networking"
  type        = string
  default     = "us-central1"
}

variable "docker_image" {
  description = "Container image URI in Artifact Registry"
  type        = string
}
