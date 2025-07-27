# Local Development Setup Guide

## Quick Start (5 minutes)

### 1. Setup Environment
```bash
# Copy the environment template
cp .env.local.example .env.local

# Edit with your project details
nano .env.local  # or use your preferred editor
```

**Required values in `.env.local`:**
```bash
export PROJECT_ID="your-actual-gcp-project-id"
export REGION="us-central1"
export GOOGLE_APPLICATION_CREDENTIALS="./keys/service-account-key.json"
```

### 2. Setup Service Account Key
```bash
# Create a directory for keys (gitignored)
mkdir -p keys

# Download your service account key from GCP Console
# Place it in: keys/service-account-key.json
```

**Alternative:** Use `gcloud` authentication:
```bash
# Instead of service account key, you can use:
gcloud auth application-default login
# Then remove GOOGLE_APPLICATION_CREDENTIALS from .env.local
```

### 3. Deploy Everything
```bash
# Full deployment (infrastructure + functions + frontend)
./scripts/deploy_local.sh

# Or deploy components separately:
./scripts/deploy_local.sh infra      # Infrastructure only
./scripts/deploy_local.sh functions  # Backend functions only
./scripts/deploy_local.sh frontend   # Frontend only
```

### 4. Handle Existing Resources (if errors occur)
```bash
# If you get "already exists" errors, import existing resources:
./scripts/import_existing.sh

# Then try deployment again:
./scripts/deploy_local.sh infra
```

## Available Commands

| Command | Description |
|---------|-------------|
| `./scripts/deploy_local.sh` | Full deployment |
| `./scripts/deploy_local.sh infra` | Infrastructure only |
| `./scripts/deploy_local.sh functions` | Backend functions only |
| `./scripts/deploy_local.sh frontend` | Frontend only |
| `./scripts/deploy_local.sh status` | Show deployment status |
| `./scripts/deploy_local.sh clean` | Clean artifacts |
| `./scripts/deploy_local.sh destroy` | Destroy infrastructure |
| `./scripts/import_existing.sh` | Import existing resources |

## Troubleshooting

### "Already exists" errors
```bash
# Run the import script to import existing resources
./scripts/import_existing.sh
```

### "API not enabled" errors
```bash
# The project module should enable all APIs, but if you get errors:
gcloud services enable <service-name> --project=$PROJECT_ID
```

### Authentication errors
```bash
# Re-authenticate with gcloud
gcloud auth application-default login
gcloud config set project $PROJECT_ID
```

### Terraform state issues
```bash
# Clean and re-initialize
./scripts/deploy_local.sh clean
./scripts/deploy_local.sh infra
```

## Directory Structure

```
Raseed/
├── .env.local                 # Your local environment (not in git)
├── .env.local.example         # Template for environment
├── keys/                      # Service account keys (gitignored)
│   └── service-account-key.json
├── scripts/
│   ├── deploy_local.sh        # Main local deployment script
│   └── import_existing.sh     # Import existing resources
├── infra/                     # Terraform infrastructure
└── logs/                      # Deployment logs (created automatically)
```

## Benefits of Local Deployment

✅ **No unnecessary commits** - Test changes locally first  
✅ **Faster iteration** - No CI/CD wait times  
✅ **Better debugging** - Direct access to logs and state  
✅ **Safe testing** - Test in isolation before pushing  
✅ **Resource management** - Handle existing resources properly  

## Integration with CI/CD

The local deployment and CI/CD use the same Terraform modules, so:
- Test locally first
- Push only when everything works
- CI/CD will apply the same changes
- No conflicts between local and remote deployments

## Security Notes

- `.env.local` is gitignored - never commit it
- `keys/` directory is gitignored - never commit service account keys  
- Use separate service accounts for local development vs production
- Regularly rotate service account keys
