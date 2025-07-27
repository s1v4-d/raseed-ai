# Terraform Vertex AI Stability Updates

## Changes Made

### 1. Enhanced Vertex AI Module (`/workspaces/Raseed/infra/modules/vertex_ai/main.tf`)

**Key Improvements:**
- **Stable Endpoint Creation**: The `google_vertex_ai_index_endpoint.receipts_ep` resource now has a fixed `display_name = "raseed-main-endpoint"`
- **Lifecycle Protection**: Added `prevent_destroy = true` and `ignore_changes` for description and labels to prevent accidental recreation
- **Versioned Deployed Index**: Changed `deployed_index_id` to `"receipts-index-v1"` for better version management
- **Create Before Destroy**: Added lifecycle rule for deployed indexes to prevent conflicts during updates

### 2. Import Discovery Script (`/workspaces/Raseed/scripts/import_existing_vertex_ai.sh`)

**Features:**
- Automatically discovers existing Vertex AI resources (endpoints, indexes, buckets)
- Generates import commands for existing resources
- Creates an auto-import script (`scripts/run_imports.sh`) for easy execution
- Preserves existing stable endpoints instead of creating duplicates

### 3. Enhanced Cleanup Script (Already Configured)

**Smart Cleanup Strategy:**
- Preserves the stable endpoint `raseed-main-endpoint` unless near quota limit (10+ endpoints)
- Only removes deployed indexes from stable endpoint, doesn't delete the endpoint itself
- Aggressively cleans up other endpoints to maintain quota compliance

## How It Works

### Stable Endpoint Strategy
1. **First Deployment**: Creates `raseed-main-endpoint` with `prevent_destroy = true`
2. **Subsequent Deployments**: Reuses the existing endpoint, only updates deployed indexes
3. **Quota Management**: Cleanup script preserves stable endpoint while removing others
4. **Import Support**: If endpoint exists outside Terraform, can be imported seamlessly

### Deployment Flow
1. **Discovery Phase**: Run `scripts/import_existing_vertex_ai.sh` to find existing resources
2. **Import Phase**: Run generated `scripts/run_imports.sh` to import existing resources into Terraform state
3. **Deploy Phase**: Run `scripts/terraform_apply.sh` for incremental updates

## Next Steps for You

### 1. Update Service Account
- Create a new service account with proper permissions
- Update the key file at `infra/secrets/raseed-test.json`
- Ensure the service account has these roles:
  - `roles/aiplatform.admin`
  - `roles/storage.admin` 
  - `roles/serviceusage.serviceUsageAdmin`

### 2. Test the Flow
```bash
# 1. Source environment
source .env.local

# 2. Setup local authentication
./scripts/setup_local_env.sh

# 3. Discover existing resources
./scripts/import_existing_vertex_ai.sh

# 4. Import existing resources (if any)
./scripts/run_imports.sh

# 5. Deploy with stable endpoint strategy
./scripts/terraform_apply.sh infra/terraform.tfvars
```

## Benefits

- **Quota Efficiency**: Reuses stable endpoints instead of creating new ones
- **Deployment Speed**: Faster deployments since endpoint creation is skipped
- **State Consistency**: Proper import handling prevents state conflicts  
- **Resource Stability**: Endpoints persist across deployments
- **Cost Optimization**: Fewer endpoint recreations means lower costs

The configuration now ensures that your Vertex AI deployment will create stable, reusable endpoints that persist across deployments while maintaining quota compliance.
