#!/bin/bash

# Check and Import Existing Resources Script
# This script checks if resources exist before importing them to avoid conflicts

set -e

# Set environment variables
if [ -f ".env.local" ]; then
    source .env.local
fi

# In CI/CD, PROJECT_ID might be set from TF_VAR_project_id
if [ -z "$PROJECT_ID" ] && [ -n "$TF_VAR_project_id" ]; then
    PROJECT_ID="$TF_VAR_project_id"
fi

if [ -z "$PROJECT_ID" ]; then
    echo "PROJECT_ID not set. Please set it in .env.local or environment"
    exit 1
fi

echo "🔍 Checking for existing resources before import for project: $PROJECT_ID"

# Function to check if a resource exists and create import block
check_and_import() {
    local resource_type="$1"
    local resource_id="$2"
    local terraform_resource="$3"
    local description="$4"
    
    echo "Checking $description..." >&2
    
    case $resource_type in
        "firebase_project")
            # Check if Firebase project is enabled
            if gcloud firebase projects list --format="value(projectId)" 2>/dev/null | grep -q "^${PROJECT_ID}$"; then
                echo "✅ Found: $description" >&2
                echo "import {"
                echo "  to = $terraform_resource"
                echo "  id = \"$resource_id\""
                echo "}"
                echo ""
                return 0
            fi
            ;;
        "firebase_hosting_site")
            # Check if Firebase hosting site exists
            if gcloud firebase hosting sites list --project="$PROJECT_ID" --format="value(name)" 2>/dev/null | grep -q "${PROJECT_ID}-hosting"; then
                echo "✅ Found: $description" >&2
                echo "import {"
                echo "  to = $terraform_resource"
                echo "  id = \"$resource_id\""
                echo "}"
                echo ""
                return 0
            fi
            ;;
        "firestore_database")
            # Check if Firestore database exists
            if gcloud firestore databases describe --database="(default)" --project="$PROJECT_ID" &>/dev/null; then
                echo "✅ Found: $description" >&2
                echo "import {"
                echo "  to = $terraform_resource"
                echo "  id = \"$resource_id\""
                echo "}"
                echo ""
                return 0
            fi
            ;;
        "storage_bucket")
            # Check if storage bucket exists
            local bucket_name=$(echo "$resource_id" | rev | cut -d'/' -f1 | rev)
            if gsutil ls -b "gs://$bucket_name" &>/dev/null; then
                echo "✅ Found: $description" >&2
                echo "import {"
                echo "  to = $terraform_resource"
                echo "  id = \"$resource_id\""
                echo "}"
                echo ""
                return 0
            fi
            ;;
        "service_account")
            # Check if service account exists
            local sa_email=$(echo "$resource_id" | rev | cut -d'/' -f1 | rev)
            if gcloud iam service-accounts describe "$sa_email" --project="$PROJECT_ID" &>/dev/null; then
                echo "✅ Found: $description" >&2
                echo "import {"
                echo "  to = $terraform_resource"
                echo "  id = \"$resource_id\""
                echo "}"
                echo ""
                return 0
            fi
            ;;
        "vertex_ai_index")
            # Check if Vertex AI index exists
            if gcloud ai indexes list --region="$REGION" --project="$PROJECT_ID" --format="value(name)" 2>/dev/null | grep -q ".*"; then
                echo "⚠️  Found Vertex AI indexes, but need manual ID verification" >&2
                echo "# Uncomment and update with actual index ID after running:"
                echo "# gcloud ai indexes list --region=$REGION --project=$PROJECT_ID"
                echo "# import {"
                echo "#   to = $terraform_resource"
                echo "#   id = \"projects/$PROJECT_ID/locations/$REGION/indexes/ACTUAL_INDEX_ID\""
                echo "# }"
                echo ""
                return 0
            fi
            ;;
        "vertex_ai_index_endpoint")
            # Check if Vertex AI index endpoint exists
            local endpoints=$(gcloud ai index-endpoints list --region="$REGION" --project="$PROJECT_ID" --format="value(name)" 2>/dev/null || echo "")
            if [ -n "$endpoints" ]; then
                echo "✅ Found Vertex AI Index Endpoints:" >&2
                echo "$endpoints" | while read -r endpoint; do
                    if [ -n "$endpoint" ]; then
                        local endpoint_id=$(echo "$endpoint" | rev | cut -d'/' -f1 | rev)
                        local display_name=$(gcloud ai index-endpoints describe "$endpoint" --region="$REGION" --project="$PROJECT_ID" --format="value(displayName)" 2>/dev/null || echo "unknown")
                        echo "  - ID: $endpoint_id, Display Name: $display_name" >&2
                        
                        # If this is our stable endpoint, create import block
                        if [ "$display_name" = "raseed-main-endpoint" ]; then
                            if ! grep -q "to = module.vertex_ai.google_vertex_ai_index_endpoint.receipts_ep" infra/imports.tf; then
                                echo "import {"
                                echo "  to = module.vertex_ai.google_vertex_ai_index_endpoint.receipts_ep"
                                echo "  id = \"$endpoint\""
                                echo "}"
                                echo ""
                            fi
                        fi
                    fi
                done
                return 0
            fi
            ;;
        "firebase_web_app")
            # Check if Firebase web app exists
            if gcloud firebase apps list --project="$PROJECT_ID" --format="value(appId)" 2>/dev/null | grep -q ".*"; then
                echo "⚠️  Found Firebase web apps, but need manual ID verification" >&2
                echo "# Uncomment and update with actual app ID after running:"
                echo "# gcloud firebase apps list --project=$PROJECT_ID"
                echo "# import {"
                echo "#   to = $terraform_resource"
                echo "#   id = \"projects/$PROJECT_ID/webApps/ACTUAL_APP_ID\""
                echo "# }"
                echo ""
                return 0
            fi
            ;;
    esac
    
    echo "❌ Not found: $description" >&2
    echo "# Resource not found, will be created: $terraform_resource"
    echo ""
    return 0
}

# Redirect output to imports.tf file
exec > infra/imports.tf

# Start with a clean file
echo "# Auto-generated imports.tf file"
echo "# Generated on $(date)"
echo "# Only import resources that actually exist"
echo ""

# Import existing resources to avoid conflicts
echo "# Import existing resources to avoid conflicts"
echo ""

# Check each resource type
check_and_import "firebase_project" \
    "$PROJECT_ID" \
    "module.firebase.google_firebase_project.this" \
    "Firebase Project"

check_and_import "firebase_hosting_site" \
    "projects/$PROJECT_ID/sites/${PROJECT_ID}-hosting" \
    "module.firebase.google_firebase_hosting_site.default" \
    "Firebase Hosting Site"

check_and_import "firestore_database" \
    "projects/$PROJECT_ID/databases/(default)" \
    "module.firestore.google_firestore_database.default" \
    "Firestore Database"

check_and_import "storage_bucket" \
    "${PROJECT_ID}-receipts" \
    "module.storage.google_storage_bucket.receipts" \
    "Receipts Storage Bucket"

check_and_import "storage_bucket" \
    "${PROJECT_ID}-index-delta" \
    "module.vertex_ai.google_storage_bucket.index_delta" \
    "Vertex AI Index Delta Bucket"

check_and_import "storage_bucket" \
    "${PROJECT_ID}-cloud-functions-source" \
    "module.cloud_functions.google_storage_bucket.code_bucket" \
    "Cloud Functions Source Bucket"

check_and_import "service_account" \
    "projects/$PROJECT_ID/serviceAccounts/wallet-issuer@${PROJECT_ID}.iam.gserviceaccount.com" \
    "module.wallet.google_service_account.wallet_sa" \
    "Wallet Service Account"

check_and_import "service_account" \
    "projects/$PROJECT_ID/serviceAccounts/cloud-functions-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
    "module.cloud_functions.google_service_account.func_sa" \
    "Cloud Functions Service Account"

check_and_import "vertex_ai_index" \
    "projects/$PROJECT_ID/locations/$REGION/indexes/PLACEHOLDER" \
    "module.vertex_ai.google_vertex_ai_index.receipts" \
    "Vertex AI Index"

check_and_import "vertex_ai_index_endpoint" \
    "projects/$PROJECT_ID/locations/$REGION/indexEndpoints/PLACEHOLDER" \
    "module.vertex_ai.google_vertex_ai_index_endpoint.receipts_ep" \
    "Vertex AI Index Endpoint"

check_and_import "firebase_web_app" \
    "projects/$PROJECT_ID/webApps/PLACEHOLDER" \
    "module.firebase.google_firebase_web_app.default" \
    "Firebase Web App"


echo "" >&2
echo "✅ Generated /workspaces/Raseed/infra/imports.tf with conditional imports" >&2
echo "" >&2
echo "📋 Summary:" >&2
echo "   - Only resources that exist will be imported" >&2
echo "   - Resources with manual ID requirements are commented with instructions" >&2
echo "   - Missing resources will be created by Terraform" >&2
echo "" >&2
echo "Next steps:" >&2
echo "1. Review the generated imports.tf file" >&2
echo "2. Update any commented import blocks with actual resource IDs" >&2
echo "3. Run terraform plan to verify the configuration" >&2
