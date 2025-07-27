#!/usr/bin/env bash
set -e
ENV_FILE=${1:-terraform.tfvars}   # default to terraform.tfvars

# Ensure we have the correct path to the tfvars file
if [[ "$ENV_FILE" != /* ]]; then
    # If it's a relative path, check if it exists in infra/ directory
    if [ -f "infra/$ENV_FILE" ]; then
        ENV_FILE="infra/$ENV_FILE"
    elif [ ! -f "$ENV_FILE" ]; then
        echo "❌ ERROR: terraform.tfvars file not found at $ENV_FILE or infra/$ENV_FILE"
        exit 1
    fi
fi

# Extract project_id from terraform vars for cleanup
PROJECT_ID=$(grep '^project_id' "$ENV_FILE" | cut -d'"' -f2 | head -1)
REGION=$(grep '^region' "$ENV_FILE" | cut -d'"' -f2 | head -1)
REGION=${REGION:-us-central1}

echo "🚀 Starting Terraform deployment"
echo "Project: $PROJECT_ID"
echo "Region: $REGION"

echo ""
echo "🔧  Running terraform init / apply"
terraform -chdir=infra init -upgrade

echo "📝 Generating imports file..."
./scripts/check_and_import_resources.sh

# Calculate relative path from infra directory to the tfvars file
if [[ "$ENV_FILE" == infra/* ]]; then
    # Remove the infra/ prefix for the terraform command
    RELATIVE_TFVARS="${ENV_FILE#infra/}"
else
    # If it's outside infra, use absolute path
    RELATIVE_TFVARS="../$ENV_FILE"
fi

terraform -chdir=infra apply -auto-approve -var-file="$RELATIVE_TFVARS"

echo ""
echo "🎉 Terraform deployment completed successfully!"
