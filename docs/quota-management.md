# Quota Management Strategy

## Overview

This document outlines our comprehensive quota management strategy to avoid deployment failures due to GCP quota limits, especially on free tier projects.

## Problem Statement

Google Cloud Platform free tier projects have strict quota limitations:
- **Vertex AI IndexEndpoints**: Maximum 15 public endpoints per project
- **Cloud Functions**: Deployment limits and regional restrictions
- **Storage Buckets**: Per-project limits
- **Service Accounts**: Creation and IAM binding limits
- **Firebase Hosting**: Site and version limits

## Solution Architecture

### 1. Stable Resource Pattern

Instead of creating new resources for each deployment, we use **stable named resources** that persist across deployments:

#### Vertex AI (Primary Fix)
- **Before**: New IndexEndpoint per deployment → Hit 15 endpoint limit
- **After**: Single stable endpoint `raseed-main-endpoint` + deployed indices
- **Benefits**: 
  - Single endpoint supports up to 20 indices
  - Stable naming prevents quota conflicts
  - `lifecycle { prevent_destroy = true }` ensures endpoint persistence

#### Cloud Functions
- **Strategy**: Stable function names (`chat-assistant`, `receipt-orchestrator`)
- **Benefits**: Overwrite existing functions instead of creating new ones
- **Source**: Stable bucket `${project_id}-cloud-functions-source` with lifecycle cleanup

#### Storage Buckets
- **Pattern**: Predictable naming (`${project_id}-receipts`, `${project_id}-index-delta`)
- **Benefits**: Reuse existing buckets, avoid creation conflicts
- **Lifecycle**: Automatic cleanup rules for temporary files

#### Service Accounts
- **Pattern**: Fixed names (`wallet-issuer@${project_id}`, `cloud-functions-sa@${project_id}`)
- **Benefits**: Stable identity, reusable across deployments
- **Authentication**: Keyless approach using Workload Identity Federation

### 2. Quota Cleanup Automation

#### Cleanup Script: `scripts/cleanup_quota.sh`

Automatically removes orphaned resources that consume quota:

```bash
./scripts/cleanup_quota.sh <project_id> [region]
```

**What it cleans:**
- Old Vertex AI IndexEndpoints (except `raseed-main-endpoint`)
- Orphaned Cloud Functions (except current ones)
- Old storage buckets (except essential ones)
- Unused service accounts (except core ones)
- Old Eventarc triggers (with manual review)

**Safety features:**
- Preserves essential resources by name pattern matching
- Shows before/after quota usage
- Graceful error handling for missing resources
- Dry-run capability for review

#### Integration Points

1. **Terraform Apply**: `scripts/terraform_apply.sh`
   - Runs cleanup before `terraform apply`
   - Extracts project_id from tfvars automatically
   - Continues on cleanup failure (non-blocking)

2. **Backend Deployment**: `scripts/deploy_backend.sh`
   - Runs cleanup before function deployment
   - Ensures clean slate for Cloud Functions

3. **CI/CD Pipeline**: GitHub Actions
   - Automated cleanup in deployment workflows
   - Prevents quota conflicts in automated deployments

### 3. Import Strategy

#### Terraform Imports: `infra/imports.tf`

Imports existing resources instead of creating conflicts:

```hcl
# Import the stable Vertex AI IndexEndpoint
import {
  to = module.vertex_ai.google_vertex_ai_index_endpoint.receipts_ep
  id = "projects/${var.project_id}/locations/${var.region}/indexEndpoints/raseed-main-endpoint"
}
```

**Covered resources:**
- Firestore database
- Storage buckets
- Service accounts
- Vertex AI resources
- Firebase project and apps
- Cloud Functions source bucket

**Usage:**
```bash
terraform -chdir=infra import -var-file=env/dev.tfvars
```

### 4. Lifecycle Management

#### Resource Persistence

Critical resources use `lifecycle` blocks to prevent accidental deletion:

```hcl
resource "google_vertex_ai_index_endpoint" "receipts_ep" {
  # ... configuration ...
  
  lifecycle {
    prevent_destroy = true
  }
}
```

#### Automatic Cleanup

Non-critical resources have automatic cleanup:

```hcl
resource "google_storage_bucket" "code_bucket" {
  # ... configuration ...
  
  lifecycle_rule {
    condition { age = 7 }
    action    { type = "Delete" }
  }
}
```

## Implementation Details

### Vertex AI Architecture

```hcl
# Single stable endpoint (quota-friendly)
resource "google_vertex_ai_index_endpoint" "receipts_ep" {
  display_name = "raseed-main-endpoint"
  # ... stable configuration ...
  
  lifecycle {
    prevent_destroy = true
  }
}

# Deployed index (replaceable)
resource "google_vertex_ai_index_endpoint_deployed_index" "receipts_deployed" {
  index_endpoint = google_vertex_ai_index_endpoint.receipts_ep.id
  index          = google_vertex_ai_index.receipts.id
  deployed_index_id = "receipts-deployed"
  # ... configuration ...
}
```

**Benefits:**
- Single endpoint for all indices (1/15 quota used)
- Index deployment is separate and replaceable
- No endpoint recreation on index updates
- Supports up to 20 indices per endpoint

### Error Recovery

#### Common Quota Errors

1. **"Exceeds maximum number of PublicEndpoint(s)"**
   - **Solution**: Run cleanup script to remove old endpoints
   - **Prevention**: Use stable endpoint pattern

2. **"Service account already exists"**
   - **Solution**: Import existing SA in terraform
   - **Prevention**: Use stable naming and imports

3. **"Bucket already exists"**
   - **Solution**: Import or use existing bucket
   - **Prevention**: Consistent naming convention

#### Monitoring

The cleanup script provides quota usage reports:

```bash
=== Current Quota Usage ===
Vertex AI Index Endpoints:
NAME                     ID
raseed-main-endpoint    projects/.../indexEndpoints/123

Cloud Functions:
NAME                 STATUS
chat-assistant      ACTIVE
receipt-orchestrator ACTIVE
```

## Best Practices

### 1. Naming Conventions

- **Vertex AI**: `raseed-main-endpoint` (stable)
- **Functions**: `chat-assistant`, `receipt-orchestrator` (stable)
- **Buckets**: `${project_id}-purpose` (predictable)
- **Service Accounts**: `purpose@${project_id}` (standard)

### 2. Deployment Workflow

1. **Pre-deployment**: Run cleanup script
2. **Import**: Import existing resources if needed
3. **Deploy**: Run terraform apply
4. **Verify**: Check quota usage
5. **Monitor**: Set up alerts for quota approaching limits

### 3. Development Guidelines

- Always use stable resource names
- Add lifecycle rules for appropriate resources
- Test quota scenarios in development
- Document any new quota-prone resources
- Update cleanup script for new resource types

## Troubleshooting

### Manual Cleanup

If automated cleanup fails:

```bash
# List and delete old endpoints manually
gcloud ai index-endpoints list --region=us-central1
gcloud ai index-endpoints delete ENDPOINT_ID --region=us-central1

# Check quota usage
gcloud compute project-info describe --format="table(quotas.metric,quotas.usage,quotas.limit)"
```

### Terraform State Issues

If terraform state becomes inconsistent:

```bash
# Remove from state and reimport
terraform state rm module.vertex_ai.google_vertex_ai_index_endpoint.receipts_ep
terraform import module.vertex_ai.google_vertex_ai_index_endpoint.receipts_ep projects/PROJECT/locations/REGION/indexEndpoints/raseed-main-endpoint
```

## Future Enhancements

1. **Quota Monitoring**: CloudWatch alerts for quota usage
2. **Automated Scaling**: Multiple endpoints when approaching limits
3. **Regional Distribution**: Spread resources across regions
4. **Cost Optimization**: Cleanup based on cost impact
5. **Resource Tagging**: Better resource lifecycle management

## Related Documentation

- [Backend Design](backend-design.md)
- [Infrastructure Design](infra-design.md)
- [Local Deployment](local-deployment.md)
- [Terraform Fixes](terraform-fixes.md)
