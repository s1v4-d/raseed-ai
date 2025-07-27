resource "google_monitoring_alert_policy" "function_errors" {
  project      = var.project_id
  display_name = "Function 5xx spikes"
  combiner     = "OR"
  conditions {
    display_name = "High error ratio"
    condition_threshold {
      filter = "resource.type=\"cloud_function\" AND metric.type=\"cloudfunctions.googleapis.com/function/execution_count\" AND metric.labels.status=\"error\""
      comparison = "COMPARISON_GT"
      duration   = "60s"
      threshold_value = 5
      aggregations {
        alignment_period = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }
  notification_channels = []
}