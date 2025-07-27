resource "google_storage_bucket" "receipts" {
  name          = "${var.project_id}-receipts"
  location      = var.region
  uniform_bucket_level_access = true
  lifecycle_rule {
    condition { age = 30 }
    action    { type = "Delete" }
  }
}

output "bucket_name" { value = google_storage_bucket.receipts.name }
