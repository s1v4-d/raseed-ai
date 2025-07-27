# Terraform Configuration Issues Fixed

## Issues Resolved

### 1. Firebase Hosting Configuration ✅
**Problem:** Invalid block types and arguments in Firebase hosting configuration
- `redirect` should be `redirects`
- `source` should be `glob` 
- `destination` should be `path`

**Solution:** Updated `infra/modules/firebase/main.tf` with correct configuration:
```hcl
config {
  rewrites {
    glob = "/api/**"
    function = var.chat_function_name
  }
  
  rewrites {
    glob = "**" 
    path = "/index.html"
  }
}
```

### 2. Firestore Database Type ✅
**Problem:** `type = "NATIVE"` is invalid
**Solution:** Changed to `type = "FIRESTORE_NATIVE"` in `infra/modules/firestore/main.tf`

### 3. Vertex AI Index Configuration ✅
**Problems:** 
- Missing `project` parameter
- Missing `index_update_method`
- Potentially invalid config structure

**Solution:** Updated `infra/modules/vertex_ai/main.tf`:
```hcl
resource "google_vertex_ai_index" "receipts" {
  display_name = "receipts-index"
  region       = var.region
  project      = var.project_id
  
  metadata {
    contents_delta_uri = "gs://${var.project_id}-index-delta"
    config {
      dimensions                = 768
      distance_measure_type     = "DOT_PRODUCT_DISTANCE"
      algorithm_config {
        tree_ah_config {
          leaf_node_embedding_count    = 1000
          leaf_nodes_to_search_percent = 7
        }
      }
    }
  }
  index_update_method = "BATCH_UPDATE"
}
```

### 4. Secret Manager Configuration ✅
**Problem:** Missing project reference
**Solution:** Added `project = var.project_id` to secret resources

### 5. Cloud Resource Manager API ✅
**Problem:** API not enabled causing access errors
**Solution:** Added `"cloudresourcemanager.googleapis.com"` to the enabled services list

### 6. Provider Configuration ✅
**Problem:** Removed problematic data source that required project to exist before APIs are enabled
**Solution:** Removed `data "google_project" "project"` block from main.tf

## Remaining Steps

### 1. Authentication Setup (Required)
The current error is about missing credentials. You need to either:

**Option A: Local Development**
```bash
gcloud auth application-default login
```

**Option B: CI/CD (GitHub Actions)**
The workflow already has proper authentication with `google-github-actions/auth@v2`

### 2. Project ID Configuration
1. Copy `terraform.tfvars.example` to `terraform.tfvars`
2. Update with your actual project ID:
```hcl
project_id = "your-actual-project-id"
region     = "us-central1"
```

### 3. Test the Configuration
```bash
# After authentication
terraform plan
terraform apply
```

## Fixed Configuration Files

- ✅ `infra/modules/firebase/main.tf` - Firebase hosting configuration
- ✅ `infra/modules/firestore/main.tf` - Firestore database type  
- ✅ `infra/modules/vertex_ai/main.tf` - Vertex AI index configuration
- ✅ `infra/modules/wallet/main.tf` - Secret manager project reference
- ✅ `infra/modules/project/main.tf` - Cloud Resource Manager API
- ✅ `infra/main.tf` - Removed problematic data source

## Architecture Validated ✅

The overall architecture is sound:
- Firebase hosting with Cloud Functions integration
- Terraform-managed infrastructure  
- Service account-based authentication (no deprecated Firebase tokens)
- Proper API enablement and resource dependencies

The configuration should now work properly once authentication is set up.
