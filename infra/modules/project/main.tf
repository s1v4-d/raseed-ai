# APIs are expected to# iamcredentials.googleapis.com

resource "google_project_service" "apis" {
  for_each = toset([
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
    "firestore.googleapis.com",
    "storage.googleapis.com",
    "cloudfunctions.googleapis.com",
    "cloudbuild.googleapis.com",
    "secretmanager.googleapis.com",
    "aiplatform.googleapis.com",
    "walletobjects.googleapis.com",
    "firebase.googleapis.com",
    "firebasehosting.googleapis.com",
    "identitytoolkit.googleapis.com",
    "eventarc.googleapis.com",
    "run.googleapis.com",
    "pubsub.googleapis.com",
    "vision.googleapis.com",
    "translate.googleapis.com",
    "speech.googleapis.com",
    "texttospeech.googleapis.com",
    "iamcredentials.googleapis.com"
  ])
  project            = var.project_id
  service            = each.key
  disable_on_destroy = false
}


resource "time_sleep" "wait_for_eventarc_sa" {
  create_duration = "60s"

  depends_on = [google_project_service.apis["eventarc.googleapis.com"]]
}
