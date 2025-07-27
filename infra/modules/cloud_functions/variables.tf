variable "project_id" {
  type        = string
  description = "The GCP project ID"
}

variable "region" {
  type        = string
  description = "The GCP region for resources"
}

variable "receipt_bucket" {
  type        = string
  description = "The name of the GCS bucket for receipts"
}
