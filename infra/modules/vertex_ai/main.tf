# Local values for generating minimal valid JSONL data
locals {
  # Create a minimal 3072-dimensional embedding (all zeros) as a valid placeholder
  # This avoids Terraform's range() limitation while creating a proper JSONL file
  minimal_embedding = join(",", concat(
    [for i in range(1024) : "0.001"],
    [for i in range(1024) : "0.001"], 
    [for i in range(1024) : "0.001"]
  ))
  
  # Create valid JSONL content (one JSON object per line)
  minimal_jsonl_content = "{\"id\":\"initial_placeholder\",\"embedding\":[${local.minimal_embedding}],\"restricts\":[{\"namespace\":\"category\",\"allow\":[\"placeholder\"]}]}\n"
}

# Create bucket for Vertex AI index data
resource "google_storage_bucket" "index_delta" {
  name          = "${var.project_id}-index-delta"
  location      = var.region
  uniform_bucket_level_access = true
  
  lifecycle_rule {
    condition { age = 90 }
    action    { type = "Delete" }
  }
}

# Create minimal JSONL file to satisfy Vertex AI index requirements
# This creates a valid but minimal index that can be extended via streaming API
resource "google_storage_bucket_object" "initial_data" {
  name   = "contents/data.json"
  bucket = google_storage_bucket.index_delta.name
  # Create a single minimal datapoint with proper JSONL format
  # Generate exactly 3072 zeros using local values to avoid range limits
  content = local.minimal_jsonl_content
  
  depends_on = [google_storage_bucket.index_delta]
}

# Create streaming index that can be populated via API
resource "google_vertex_ai_index" "receipts" {
  display_name = "receipts-index"
  region       = var.region
  project      = var.project_id
  
  metadata {
    # Point to directory containing initial minimal data
    contents_delta_uri = "gs://${google_storage_bucket.index_delta.name}/contents"
    config {
      dimensions                = 3072
      approximate_neighbors_count = 150
      distance_measure_type     = "DOT_PRODUCT_DISTANCE"
      algorithm_config {
        tree_ah_config {
          leaf_node_embedding_count    = 1000
          leaf_nodes_to_search_percent = 7
        }
      }
    }
  }
  # Use streaming updates for real-time ingestion of new data
  index_update_method = "STREAM_UPDATE"
  
  depends_on = [
    google_storage_bucket.index_delta,
    google_storage_bucket_object.initial_data
  ]
}

# Single stable IndexEndpoint that can host multiple indices (up to 20)
# Using a fixed display_name and prevent_destroy to ensure stability
resource "google_vertex_ai_index_endpoint" "receipts_ep" {
  display_name            = "raseed-main-endpoint"
  description             = "Reusable endpoint for all Raseed indices"
  region                  = var.region
  project                 = var.project_id
  public_endpoint_enabled = true
  
  # Add lifecycle to prevent destruction and recreation
  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      # Ignore description changes to prevent recreation
      description,
      # Ignore labels that might be added by other systems
      labels
    ]
  }
}

# Deploy the receipts index to the stable endpoint
resource "google_vertex_ai_index_endpoint_deployed_index" "receipts_deployed" {
  deployed_index_id     = "receipts_index_v1"
  display_name          = "Receipts Index Deployment"
  index                 = google_vertex_ai_index.receipts.id
  index_endpoint        = google_vertex_ai_index_endpoint.receipts_ep.id
  enable_access_logging = false
  
  # Use automatic resources for simple scaling
  automatic_resources {
    min_replica_count = 1
    max_replica_count = 2
  }
  
  depends_on = [
    google_vertex_ai_index.receipts,
    google_vertex_ai_index_endpoint.receipts_ep
  ]
  
  lifecycle {
    # Replace deployment instead of update to avoid conflicts
    create_before_destroy = true
  }
}

output "index_endpoint" { 
  value = google_vertex_ai_index_endpoint.receipts_ep.name
}

output "index_endpoint_id" {
  value = google_vertex_ai_index_endpoint.receipts_ep.id
}

output "deployed_index_name" {
  value = google_vertex_ai_index_endpoint_deployed_index.receipts_deployed.name
}

output "endpoint_display_name" {
  value = google_vertex_ai_index_endpoint.receipts_ep.display_name
  description = "The display name of the endpoint for import reference"
}
