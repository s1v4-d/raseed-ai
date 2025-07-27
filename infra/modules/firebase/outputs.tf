output "hosting_site_id" {
  description = "The Firebase Hosting site ID"
  value       = google_firebase_hosting_site.default.site_id
}

output "hosting_url" {
  description = "The Firebase Hosting URL"
  value       = "https://${google_firebase_hosting_site.default.site_id}.web.app"
}

output "web_app_config" {
  description = "Firebase web app configuration"
  value = {
    app_id     = google_firebase_web_app.default.app_id
    project_id = var.project_id
  }
}
