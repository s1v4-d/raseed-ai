# Infrastructure Design

## Terraform Root Module
- Wires together all sub-modules: project, storage, firestore, vertex_ai, wallet, cloud_functions, monitoring
- Environment-specific variables via `infra/env/*.tfvars`

## Modules
- **project/**: Enables required GCP APIs
- **storage/**: Creates receipts bucket, IAM for Cloud Functions
- **firestore/**: (optional) Firestore DB setup
- **vertex_ai/**: Embeddings, Matching Engine index
- **wallet/**: Service account, IAM, Secret Manager for Wallet API
- **cloud_functions/**: Deploys orchestrator & chat functions
- **monitoring/**: Log-based metrics, uptime checks, budget alerts

## Security
- Least-privilege IAM for all service accounts
- Secret Manager for sensitive keys
- Buckets use uniform access, auto-delete after 30 days

## Deployment
- One-command: `./scripts/terraform_apply.sh -var-file infra/env/dev.tfvars`
- See [README.md](../README.md) for full steps

## Monitoring
- Alert policies for function errors, budget
- Log-based metrics

See [architecture.md](architecture.md) for component overview.
