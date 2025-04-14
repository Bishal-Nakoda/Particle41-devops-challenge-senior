variable "state_files_bucket_id" {
  description = "State file bucket"
  type        = string
}

variable "ip" {
  description = "IP which is mapped to DNS"
  type        = string
}

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

variable "domains" {
  description = "Domain you want"
  type        = string
}

variable "gcp_service_list" {
  description = "The list of apis necessary for the project"
  type        = list(string)
  default = [
    "compute.googleapis.com",
    "iap.googleapis.com",
    "vpcaccess.googleapis.com",
    "run.googleapis.com"
  ]
}
