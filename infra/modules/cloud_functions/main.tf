# Get project details for service agents
data "google_project" "project" {
  project_id = var.project_id
}

# Create service account for Cloud Functions
resource "google_service_account" "func_sa" {
  project      = var.project_id
  account_id   = "cloud-functions-sa"
  display_name = "Cloud Functions Service Account"
}

# Grant necessary permissions to the service account for accessing Firestore
# Cloud Functions need various permissions for logs, storage, and Firestore access
resource "google_project_iam_member" "cloud_functions_logs" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.func_sa.email}"
  
  depends_on = [google_service_account.func_sa]
}

resource "google_project_iam_member" "cloud_functions_firestore_user" {
  project = var.project_id
  role    = "roles/datastore.user"
  member  = "serviceAccount:${google_service_account.func_sa.email}"
  
  depends_on = [google_service_account.func_sa]
}

# Grant Cloud Functions service account the Event Receiver role
# Required for receiving events from Eventarc triggers
resource "google_project_iam_member" "cloud_functions_event_receiver" {
  project = var.project_id
  role    = "roles/eventarc.eventReceiver"
  member  = "serviceAccount:${google_service_account.func_sa.email}"
  
  depends_on = [google_service_account.func_sa]
}

# Grant Cloud Functions service account the Run Invoker role
# Required for invoking the underlying Cloud Run service
resource "google_project_iam_member" "cloud_functions_run_invoker" {
  project = var.project_id
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.func_sa.email}"
  
  depends_on = [google_service_account.func_sa]
}

# Grant Cloud Functions service account Vertex AI User role
# Required for accessing Vertex AI services (embeddings, indexing)
resource "google_project_iam_member" "cloud_functions_vertex_ai_user" {
  project = var.project_id
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:${google_service_account.func_sa.email}"
  
  depends_on = [google_service_account.func_sa]
}

# Grant Cloud Functions service account Translation API User role
# Required for using Google Cloud Translation API
resource "google_project_iam_member" "cloud_functions_translation_user" {
  project = var.project_id
  role    = "roles/cloudtranslate.user"
  member  = "serviceAccount:${google_service_account.func_sa.email}"
  
  depends_on = [google_service_account.func_sa]
}

# Grant Cloud Functions service account Vision API User role
# Required for using Google Cloud Vision API
resource "google_project_iam_member" "cloud_functions_vision_user" {
  project = var.project_id
  role    = "roles/ml.admin"
  member  = "serviceAccount:${google_service_account.func_sa.email}"
  
  depends_on = [google_service_account.func_sa]
}

# Enable Eventarc and Pub/Sub APIs
resource "google_project_service" "eventarc_api" {
  project            = var.project_id
  service            = "eventarc.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "pubsub_api" {
  project            = var.project_id
  service            = "pubsub.googleapis.com"
  disable_on_destroy = false
}

# Create service identities for Eventarc and Pub/Sub
resource "google_project_service_identity" "eventarc_sa" {
  provider = google-beta
  project  = var.project_id
  service  = "eventarc.googleapis.com"

  depends_on = [google_project_service.eventarc_api]
}

resource "google_project_service_identity" "pubsub_sa" {
  provider = google-beta
  project  = var.project_id
  service  = "pubsub.googleapis.com"

  depends_on = [google_project_service.pubsub_api]
}

# Grant Eventarc Service Agent the required role for event triggers
resource "google_project_iam_member" "eventarc_service_agent" {
  project = var.project_id
  role    = "roles/eventarc.serviceAgent"
  member  = "serviceAccount:${google_project_service_identity.eventarc_sa.email}"

  depends_on = [google_project_service_identity.eventarc_sa]
}

# Grant Pub/Sub Service Agent role for event delivery
resource "google_project_iam_member" "eventarc_pubsub_service_agent" {
  project = var.project_id
  role    = "roles/pubsub.serviceAgent"
  member  = "serviceAccount:${google_project_service_identity.pubsub_sa.email}"

  depends_on = [google_project_service_identity.pubsub_sa]
}

# Grant Pub/Sub Service Agent the Service Account Token Creator role
# Required for Pub/Sub triggers to work with Eventarc
resource "google_project_iam_member" "pubsub_service_agent_token_creator" {
  project = var.project_id
  role    = "roles/iam.serviceAccountTokenCreator"
  member  = "serviceAccount:${google_project_service_identity.pubsub_sa.email}"

  depends_on = [google_project_service_identity.pubsub_sa]
}

# Grant GCS service account Pub/Sub Publisher role for GCS event triggers
# Required for GCS CloudEvent triggers to work with Eventarc
data "google_storage_project_service_account" "gcs_account" {}

resource "google_project_iam_member" "gcs_pubsub_publishing" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"
  
  depends_on = [google_service_account.func_sa]
}

# Create bucket for function source code
resource "google_storage_bucket" "code_bucket" {
  name          = "${var.project_id}-cloud-functions-source"
  location      = var.region
  uniform_bucket_level_access = true
  
  lifecycle_rule {
    condition { age = 7 }
    action    { type = "Delete" }
  }
}

# For now, we'll use gcloud commands in CI/CD to deploy functions
# This creates the service account that will be used by the functions

output "functions_sa_email" {
  value = google_service_account.func_sa.email
}

output "chat_url" {
  value = "https://${var.region}-${var.project_id}.cloudfunctions.net/chat-assistant"
}
