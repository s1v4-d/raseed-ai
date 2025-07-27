variable "project_id" {
  type        = string
  description = "The GCP project ID"
}

variable "region" {
  type        = string
  description = "The GCP region for resources"
  default     = "us-central1"
}

variable "credentials" {
  type        = string
  description = "Path to GCP service account key file. If not provided, will use Application Default Credentials (ADC)"
  default     = ""
}
