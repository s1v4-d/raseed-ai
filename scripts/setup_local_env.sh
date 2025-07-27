#!/bin/bash

# Local Development Environment Setup Script
# Run this script with: source ./scripts/setup_local_env.sh

set -e

echo "🔧 Setting up local development environment..."

# Load environment variables (which now sources from terraform.tfvars)
if [ -f "/workspaces/Raseed/.env.local" ]; then
    source /workspaces/Raseed/.env.local
    echo "✅ Loaded environment variables from .env.local"
    echo "   Project ID: $PROJECT_ID (from terraform.tfvars)"
    echo "   Region: $REGION (from terraform.tfvars)"
else
    echo "❌ .env.local file not found"
    exit 1
fi

# Check if gcloud is available
if ! command -v gcloud &> /dev/null; then
    echo "❌ gcloud CLI not found in PATH"
    echo "   Expected: /workspaces/Raseed/gcli/google-cloud-sdk/bin/gcloud"
    exit 1
fi

echo "✅ gcloud CLI found: $(which gcloud)"

# Check service account key
if [ ! -f "$GOOGLE_APPLICATION_CREDENTIALS" ]; then
    echo "❌ Service account key not found: $GOOGLE_APPLICATION_CREDENTIALS"
    exit 1
fi

# Verify gcloud authentication
if gcloud auth list --filter="status:ACTIVE" --format="value(account)" | grep -q "@${PROJECT_ID}.iam.gserviceaccount.com"; then
    echo "✅ gcloud authenticated with service account"
else
    echo "🔑 Authenticating gcloud with service account..."
    gcloud auth activate-service-account --key-file="$GOOGLE_APPLICATION_CREDENTIALS" --quiet
    echo "✅ Authentication successful"
fi

# Set project and region
echo "🎯 Configuring gcloud defaults..."
gcloud config set project "$PROJECT_ID" --quiet
gcloud config set compute/region "$REGION" --quiet

# Check quota status
echo "📊 Checking Vertex AI quota status..."
ENDPOINT_COUNT=$(gcloud ai index-endpoints list \
    --region="$REGION" \
    --format="value(name)" 2>/dev/null | wc -l || echo "0")

echo "   Current endpoints: $ENDPOINT_COUNT/15 (quota limit)"

if [ "$ENDPOINT_COUNT" -ge 13 ]; then
    echo "⚠️  WARNING: Close to quota limit!"
    echo "   Consider running: ./scripts/emergency_vertex_cleanup.sh $PROJECT_ID $REGION"
fi

echo "✅ Environment setup complete!"
echo ""
echo "Current configuration:"
echo "  Project: $(gcloud config get-value project)"
echo "  Region: $(gcloud config get-value compute/region)"
echo "  Account: $(gcloud config get-value account)"
echo ""
echo "Available commands:"
echo "  ./scripts/emergency_vertex_cleanup.sh  # Clear quota if needed"
echo "  ./scripts/terraform_apply.sh           # Deploy infrastructure"
echo "  ./scripts/deploy_backend.sh            # Deploy backend services"
