# Firebase Project Setup
resource "google_firebase_project" "this" {
  provider = google-beta
  project  = var.project_id
}

# Firebase Web App
resource "google_firebase_web_app" "default" {
  provider     = google-beta
  project      = var.project_id
  display_name = "Raseed Web App"
  
  depends_on = [google_firebase_project.this]
}

# Firebase Hosting Site
resource "google_firebase_hosting_site" "default" {
  provider = google-beta
  project  = var.project_id
  site_id  = "${var.project_id}-hosting"
  app_id   = google_firebase_web_app.default.app_id
  
  depends_on = [google_firebase_project.this]
}

# Firebase Hosting Version - Configure to serve static Flutter web build
resource "google_firebase_hosting_version" "default" {
  provider = google-beta
  site_id  = google_firebase_hosting_site.default.site_id
  
  config {
    # API rewrites to Cloud Functions
    rewrites {
      glob = "/api/**"
      function = var.chat_function_name
    }
    
    # SPA fallback
    rewrites {
      glob = "**"
      path = "/index.html"
    }
  }
  
  depends_on = [google_firebase_hosting_site.default]
}

# Firebase Hosting Release
resource "google_firebase_hosting_release" "default" {
  provider     = google-beta
  site_id      = google_firebase_hosting_site.default.site_id
  version_name = google_firebase_hosting_version.default.name
  message      = "Terraform managed release"
  
  depends_on = [google_firebase_hosting_version.default]
}
