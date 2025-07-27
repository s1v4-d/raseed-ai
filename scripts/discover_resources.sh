#!/bin/bash

# Script to discover actual Google Cloud resource IDs for Terraform imports
# This helps identify the real resource names that need to be imported

set -e

PROJECT_ID="${1:-$GOOGLE_CLOUD_PROJECT}"
REGION="${2:-us-central1}"

if [ -z "$PROJECT_ID" ]; then
    echo "Usage: $0 <project_id> [region]"
    echo "Or set GOOGLE_CLOUD_PROJECT environment variable"
    exit 1
fi

echo "Discovering resource IDs for project: $PROJECT_ID"
echo "Region: $REGION"
echo ""

# Function to check if gcloud command exists
check_gcloud() {
    if ! command -v gcloud &> /dev/null; then
        echo "gcloud CLI not found. Please install Google Cloud SDK."
        exit 1
    fi
}

# Function to discover Firebase web apps
discover_firebase_apps() {
    echo "=== Firebase Web Apps ==="
    echo "Discovering Firebase web apps..."
    
    APPS=$(gcloud firebase apps list --project=$PROJECT_ID --format="table(name,displayName,appId)" 2>/dev/null || true)
    
    if [ -n "$APPS" ]; then
        echo "$APPS"
        echo ""
        echo "Import commands for Firebase web apps:"
        gcloud firebase apps list --project=$PROJECT_ID --format="value(appId)" 2>/dev/null | while read app_id; do
            if [ -n "$app_id" ]; then
                echo "import {"
                echo "  to = module.firebase.google_firebase_web_app.default"
                echo "  id = \"projects/$PROJECT_ID/webApps/$app_id\""
                echo "}"
                echo ""
            fi
        done
    else
        echo "No Firebase web apps found or Firebase API not enabled"
    fi
    echo ""
}

# Function to discover Vertex AI Index Endpoints
discover_vertex_ai_endpoints() {
    echo "=== Vertex AI Index Endpoints ==="
    echo "Discovering Vertex AI index endpoints..."
    
    ENDPOINTS=$(gcloud ai index-endpoints list --region=$REGION --project=$PROJECT_ID --format="table(name,displayName)" 2>/dev/null || true)
    
    if [ -n "$ENDPOINTS" ]; then
        echo "$ENDPOINTS"
        echo ""
        echo "Import commands for Vertex AI index endpoints:"
        gcloud ai index-endpoints list --region=$REGION --project=$PROJECT_ID --format="value(name)" 2>/dev/null | while read endpoint_name; do
            if [ -n "$endpoint_name" ]; then
                # Extract the endpoint ID from the full name
                endpoint_id=$(echo "$endpoint_name" | sed 's|.*/indexEndpoints/||')
                echo "import {"
                echo "  to = module.vertex_ai.google_vertex_ai_index_endpoint.receipts_ep"
                echo "  id = \"$endpoint_name\""
                echo "}"
                echo "# Endpoint ID: $endpoint_id"
                echo ""
            fi
        done
    else
        echo "No Vertex AI index endpoints found or Vertex AI API not enabled"
    fi
    echo ""
}

# Function to discover Vertex AI Indexes
discover_vertex_ai_indexes() {
    echo "=== Vertex AI Indexes ==="
    echo "Discovering Vertex AI indexes..."
    
    INDEXES=$(gcloud ai indexes list --region=$REGION --project=$PROJECT_ID --format="table(name,displayName)" 2>/dev/null || true)
    
    if [ -n "$INDEXES" ]; then
        echo "$INDEXES"
        echo ""
        echo "Import commands for Vertex AI indexes:"
        gcloud ai indexes list --region=$REGION --project=$PROJECT_ID --format="value(name)" 2>/dev/null | while read index_name; do
            if [ -n "$index_name" ]; then
                # Extract the index ID from the full name
                index_id=$(echo "$index_name" | sed 's|.*/indexes/||')
                echo "import {"
                echo "  to = module.vertex_ai.google_vertex_ai_index.receipts"
                echo "  id = \"$index_name\""
                echo "}"
                echo "# Index ID: $index_id"
                echo ""
            fi
        done
    else
        echo "No Vertex AI indexes found or Vertex AI API not enabled"
    fi
    echo ""
}

# Function to discover Firebase hosting sites
discover_firebase_hosting() {
    echo "=== Firebase Hosting Sites ==="
    echo "Discovering Firebase hosting sites..."
    
    SITES=$(gcloud firebase hosting sites list --project=$PROJECT_ID --format="table(name,site_id)" 2>/dev/null || true)
    
    if [ -n "$SITES" ]; then
        echo "$SITES"
        echo ""
        echo "Import commands for Firebase hosting sites:"
        gcloud firebase hosting sites list --project=$PROJECT_ID --format="value(name)" 2>/dev/null | while read site_name; do
            if [ -n "$site_name" ]; then
                # Extract the site ID from the full name
                site_id=$(echo "$site_name" | sed 's|.*/sites/||')
                echo "import {"
                echo "  to = module.firebase.google_firebase_hosting_site.default"
                echo "  id = \"$site_name\""
                echo "}"
                echo "# Site ID: $site_id"
                echo ""
            fi
        done
    else
        echo "No Firebase hosting sites found or Firebase API not enabled"
    fi
    echo ""
}

# Function to discover service accounts
discover_service_accounts() {
    echo "=== Service Accounts ==="
    echo "Discovering relevant service accounts..."
    
    SAS=$(gcloud iam service-accounts list --project=$PROJECT_ID --format="table(email,displayName)" --filter="email:wallet-issuer OR email:cloud-functions-sa" 2>/dev/null || true)
    
    if [ -n "$SAS" ]; then
        echo "$SAS"
        echo ""
        echo "Import commands for service accounts:"
        gcloud iam service-accounts list --project=$PROJECT_ID --format="value(email)" --filter="email:wallet-issuer OR email:cloud-functions-sa" 2>/dev/null | while read sa_email; do
            if [ -n "$sa_email" ]; then
                if [[ "$sa_email" == *"wallet-issuer"* ]]; then
                    echo "import {"
                    echo "  to = module.wallet.google_service_account.wallet_sa"
                    echo "  id = \"projects/$PROJECT_ID/serviceAccounts/$sa_email\""
                    echo "}"
                elif [[ "$sa_email" == *"cloud-functions-sa"* ]]; then
                    echo "import {"
                    echo "  to = module.cloud_functions.google_service_account.func_sa"
                    echo "  id = \"projects/$PROJECT_ID/serviceAccounts/$sa_email\""
                    echo "}"
                fi
                echo ""
            fi
        done
    else
        echo "No relevant service accounts found"
    fi
    echo ""
}

# Function to discover storage buckets
discover_storage_buckets() {
    echo "=== Storage Buckets ==="
    echo "Discovering relevant storage buckets..."
    
    BUCKETS=$(gsutil ls -p $PROJECT_ID 2>/dev/null | grep -E "(receipts|index-delta|cloud-functions-source)" || true)
    
    if [ -n "$BUCKETS" ]; then
        echo "Found buckets:"
        echo "$BUCKETS"
        echo ""
        echo "Import commands for storage buckets:"
        echo "$BUCKETS" | while read bucket_url; do
            if [ -n "$bucket_url" ]; then
                bucket_name=$(echo "$bucket_url" | sed 's|gs://||' | sed 's|/||')
                if [[ "$bucket_name" == *"receipts"* ]]; then
                    echo "import {"
                    echo "  to = module.storage.google_storage_bucket.receipts"
                    echo "  id = \"$bucket_name\""
                    echo "}"
                elif [[ "$bucket_name" == *"index-delta"* ]]; then
                    echo "import {"
                    echo "  to = module.vertex_ai.google_storage_bucket.index_delta"
                    echo "  id = \"$bucket_name\""
                    echo "}"
                elif [[ "$bucket_name" == *"cloud-functions-source"* ]]; then
                    echo "import {"
                    echo "  to = module.cloud_functions.google_storage_bucket.code_bucket"
                    echo "  id = \"$bucket_name\""
                    echo "}"
                fi
                echo ""
            fi
        done
    else
        echo "No relevant storage buckets found"
    fi
    echo ""
}

main() {
    check_gcloud
    
    echo "Starting resource discovery..."
    echo "=============================================="
    
    discover_firebase_apps
    discover_vertex_ai_endpoints
    discover_vertex_ai_indexes
    discover_firebase_hosting
    discover_service_accounts
    discover_storage_buckets
    
    echo "=============================================="
    echo "Resource discovery completed!"
    echo ""
    echo "Instructions:"
    echo "1. Copy the relevant import commands to your imports.tf file"
    echo "2. Run 'terraform plan' to verify the imports"
    echo "3. Run 'terraform apply' to proceed with deployment"
}

# Run main function
main "$@"
