# Authentication Setup Guide

## Overview

The Terraform configuration now supports flexible authentication methods following Google Cloud best practices:

## Configuration Changes Made

### 1. Added Credentials Variable

**File:** `infra/variables.tf`
```hcl
variable "credentials" {
  type        = string
  description = "Path to GCP service account key file. If not provided, will use Application Default Credentials (ADC)"
  default     = ""
}
```

### 2. Updated Provider Configuration

**File:** `infra/main.tf`
```hcl
provider "google" {
  credentials = var.credentials != "" ? file(var.credentials) : null
  project     = var.project_id
  region      = var.region
}

provider "google-beta" {
  credentials = var.credentials != "" ? file(var.credentials) : null
  project     = var.project_id
  region      = var.region
}
```

### 3. Updated terraform.tfvars

**File:** `infra/terraform.tfvars`
```hcl
project_id = "raseed-test"
region     = "us-central1"
credentials = "secrets/raseed-test.json"
```

## Authentication Methods

### Method 1: Service Account Key File (Current)

For local development with service account keys:

```bash
# Ensure your service account key is in the correct location
ls infra/secrets/raseed-test.json

# Run Terraform
cd infra
terraform plan
terraform apply
```

### Method 2: Application Default Credentials (Recommended)

For environments where ADC is preferred:

1. **Setup ADC:**
   ```bash
   gcloud auth application-default login
   ```

2. **Update terraform.tfvars:**
   ```hcl
   project_id = "raseed-test"
   region     = "us-central1"
   credentials = ""  # Empty string to use ADC
   ```

3. **Run Terraform:**
   ```bash
   cd infra
   terraform plan
   terraform apply
   ```

### Method 3: Environment Variables

The provider also supports these environment variables (in order of precedence):

1. `GOOGLE_CREDENTIALS` - JSON content of service account key
2. `GOOGLE_CLOUD_KEYFILE_JSON` - JSON content of service account key  
3. `GCLOUD_KEYFILE_JSON` - JSON content of service account key
4. `GOOGLE_APPLICATION_CREDENTIALS` - Path to service account key file

## Best Practices

### For Local Development
- Use service account keys or ADC
- Keep service account keys in `infra/secrets/` (gitignored)
- Use separate service accounts for dev vs prod

### For CI/CD
- Use Workload Identity Federation (recommended)
- Or use service account keys stored in secrets
- Never commit service account keys to git

### For Production
- Use Workload Identity Federation
- Use minimal IAM permissions
- Regularly rotate service account keys

## Troubleshooting

### Error: "No credentials loaded"
- Ensure service account key exists at the specified path
- Or run `gcloud auth application-default login`
- Check that `GOOGLE_APPLICATION_CREDENTIALS` environment variable is not conflicting

### Error: "Permission denied"
- Verify service account has required roles:
  - `roles/editor` or specific service roles
  - `roles/serviceusage.serviceUsageAdmin` (for API enablement)
  - `roles/iam.serviceAccountAdmin` (for service account management)

### Error: "Invalid credentials"
- Verify service account key file is valid JSON
- Check that the service account hasn't been deleted
- Ensure the key hasn't expired

## Migration from Previous Setup

The previous configuration was hardcoded to use `secrets/raseed-test.json`. This new approach:

1. ✅ **Maintains backward compatibility** - existing setups continue working
2. ✅ **Adds flexibility** - supports ADC and environment variables  
3. ✅ **Follows best practices** - aligns with Google Cloud documentation
4. ✅ **Improves security** - enables ADC for environments that support it

## Next Steps

1. Test the current configuration: `terraform plan`
2. For production deployment, consider migrating to ADC or Workload Identity Federation
3. Set up proper IAM roles for the service account
4. Enable required APIs in the GCP console or via gcloud

## References

- [Google Cloud Authentication Documentation](https://cloud.google.com/docs/authentication)
- [Terraform Google Provider Authentication](https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/provider_reference#authentication)
- [Service Account Best Practices](https://cloud.google.com/iam/docs/best-practices-service-accounts)
