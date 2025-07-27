# Enable required APIs for this module
resource "google_project_service" "iam_credentials_api" {
  project            = var.project_id
  service            = "iamcredentials.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "secret_manager_api" {
  project            = var.project_id
  service            = "secretmanager.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "wallet_objects_api" {
  project            = var.project_id
  service            = "walletobjects.googleapis.com"
  disable_on_destroy = false
}

# Create wallet service account for Google Wallet API access
resource "google_service_account" "wallet_sa" {
  account_id   = "wallet-issuer"
  display_name = "Google Wallet issuer SA"
  project      = var.project_id
}

# Grant necessary permissions for Google Wallet operations
# The 'roles/walletobjects.issuer' role CANNOT be granted via IAM.
# It must be assigned manually in the Google Pay & Wallet Console.
# 1. Go to the Google Pay & Wallet Console.
# 2. Select your Issuer ID.
# 3. Go to the "Users" tab.
# 4. Add the service account email created by this module as a user with
#    'Owner' or 'Writer' permissions.
#    The email is: "${google_service_account.wallet_sa.email}"

# Grant the service account permission to generate its own access tokens
# This enables keyless authentication using service account impersonation
resource "google_service_account_iam_member" "wallet_token_creator" {
  service_account_id = google_service_account.wallet_sa.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${google_service_account.wallet_sa.email}"
  
  depends_on = [google_service_account.wallet_sa]
}

# Store the service account email in Secret Manager for application use
# Applications can use this to impersonate the service account without keys
resource "google_secret_manager_secret" "wallet_sa_email" {
  secret_id = "wallet-issuer-email"
  project   = var.project_id
  replication { 
    auto {}
  }
  
  depends_on = [
    google_project_service.iam_credentials_api,
    google_project_service.secret_manager_api,
    google_project_service.wallet_objects_api
  ]
}

resource "google_secret_manager_secret_version" "wallet_sa_email_ver" {
  secret      = google_secret_manager_secret.wallet_sa_email.id
  secret_data = google_service_account.wallet_sa.email
  
  depends_on = [google_secret_manager_secret.wallet_sa_email]
}

# Output the service account email for use by applications
output "wallet_sa_email" { 
  value = google_service_account.wallet_sa.email 
}

# Output the secret ID containing the service account email
output "wallet_sa_email_secret_id" {
  value = google_secret_manager_secret.wallet_sa_email.secret_id
}
