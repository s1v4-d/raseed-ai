# Firestore module for Raseed (optional, for explicit Firestore DB provisioning)

resource "google_firestore_database" "default" {
  project     = var.project_id
  name        = "(default)"
  location_id = var.region
  type        = "FIRESTORE_NATIVE"
}

# Optionally, you can add indexes or security rules deployment here if needed.

output "firestore_database_name" {
  value = google_firestore_database.default.name
}
