#!/usr/bin/env bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

log "🚀 Starting local deployment for Raseed project"
log "Project root: $PROJECT_ROOT"

# Check if .env.local exists
if [ ! -f "$PROJECT_ROOT/.env.local" ]; then
    error ".env.local file not found!"
    log "Please copy .env.local.example to .env.local and configure your values:"
    log "  cp .env.local.example .env.local"
    log "  # Edit .env.local with your project details"
    exit 1
fi

# Load environment variables
log "📋 Loading environment variables from .env.local"
source "$PROJECT_ROOT/.env.local"

# Validate required variables
if [ -z "$PROJECT_ID" ]; then
    error "PROJECT_ID is not set in .env.local"
    exit 1
fi

if [ -z "$GOOGLE_APPLICATION_CREDENTIALS" ] && [ -z "$GOOGLE_CREDENTIALS" ]; then
    error "Either GOOGLE_APPLICATION_CREDENTIALS or GOOGLE_CREDENTIALS must be set"
    exit 1
fi

log "Using project: $PROJECT_ID"
log "Using region: ${REGION:-us-central1}"

# Create logs directory
mkdir -p "$PROJECT_ROOT/logs"

# Validate gcloud auth
log "🔐 Checking Google Cloud authentication"
if [ -n "$GOOGLE_APPLICATION_CREDENTIALS" ] && [ -f "$GOOGLE_APPLICATION_CREDENTIALS" ]; then
    log "🔑 Authenticating gcloud with service account from $GOOGLE_APPLICATION_CREDENTIALS..."
    gcloud auth activate-service-account --key-file="$GOOGLE_APPLICATION_CREDENTIALS" --project="$PROJECT_ID" --quiet
    log "✅ Service account authentication successful"
elif ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    warning "No active gcloud authentication found and no service account key provided."
    log "Trying to login with Application Default Credentials..."
    gcloud auth application-default login --project="$PROJECT_ID"
fi

# Set gcloud project
gcloud config set project "$PROJECT_ID"

# Function to run terraform with proper error handling
run_terraform() {
    local command="$1"
    local description="$2"
    
    log "🏗️ $description"
    cd "$PROJECT_ROOT"
    
    case "$command" in
        "apply")
            ./scripts/terraform_apply.sh
            ;;
        "destroy")
            cd "$PROJECT_ROOT/infra"
            terraform destroy -auto-approve -var-file="../.env.local"
            ;;
        *)
            cd "$PROJECT_ROOT/infra"
            terraform "$command"
            ;;
    esac
}

# Function to handle existing resources
handle_existing_resources() {
    log "🔄 Checking for existing resources and generating imports file..."
    "$PROJECT_ROOT/scripts/check_and_import_resources.sh" || warning "Import script failed, continuing with apply..."
}

# Function to deploy backend functions
deploy_functions() {
    log "🔧 Deploying Cloud Functions"
    
    # Get terraform outputs
    cd "$PROJECT_ROOT/infra"
    RECEIPT_BUCKET=$(terraform output -raw receipt_bucket 2>/dev/null || echo "$PROJECT_ID-receipts")
    FUNCTIONS_SA=$(terraform output -raw functions_sa_email 2>/dev/null || echo "cloud-functions-sa@$PROJECT_ID.iam.gserviceaccount.com")
    
    export RECEIPT_BUCKET
    export FUNCTIONS_SA
    export REGION="${REGION:-us-central1}"
    
    log "Using receipt bucket: $RECEIPT_BUCKET"
    log "Using functions service account: $FUNCTIONS_SA"
    
    # Deploy functions
    if [ -f "$PROJECT_ROOT/scripts/deploy_backend.sh" ]; then
        log "Running backend deployment script"
        cd "$PROJECT_ROOT"
        chmod +x scripts/deploy_backend.sh
        ./scripts/deploy_backend.sh --env local
    else
        warning "Backend deployment script not found, skipping function deployment"
    fi
}

# Function to build and deploy frontend
deploy_frontend() {
    log "🌐 Building and deploying frontend"
    
    cd "$PROJECT_ROOT/frontend"
    
    # Install dependencies if needed
    if [ ! -d "build" ]; then
        log "Installing Flutter dependencies..."
        flutter pub get
    fi
    
    # Build web app
    log "Building Flutter web app..."
    flutter build web --release
    
    # Deploy to Firebase Hosting
    cd "$PROJECT_ROOT"
    
    # Get hosting site ID from terraform
    HOSTING_SITE_ID=$(cd infra && terraform output -raw hosting_site_id 2>/dev/null || echo "$PROJECT_ID-hosting")
    
    log "Deploying to Firebase Hosting site: $HOSTING_SITE_ID"
    
    # Ensure firebase CLI is available
    if ! command -v firebase &> /dev/null; then
        log "Installing Firebase CLI..."
        npm install -g firebase-tools
    fi
    
    # Copy build files
    mkdir -p build/web
    cp -r frontend/build/web/* build/web/
    
    # Deploy using ADC
    firebase use "$PROJECT_ID"
    firebase deploy --only hosting:"$HOSTING_SITE_ID"
}

# Main deployment function
main() {
    case "${1:-all}" in
        "infra"|"terraform")
            log "🏗️ Deploying infrastructure only"
            run_terraform "init" "Initializing Terraform"
            handle_existing_resources
            run_terraform "plan" "Planning infrastructure changes"
            run_terraform "apply" "Applying infrastructure changes"
            success "Infrastructure deployment completed!"
            ;;
        "functions"|"backend")
            log "🔧 Deploying backend functions only"
            deploy_functions
            success "Backend deployment completed!"
            ;;
        "frontend"|"web")
            log "🌐 Deploying frontend only"
            deploy_frontend
            success "Frontend deployment completed!"
            ;;
        "clean")
            log "🧹 Cleaning up deployment artifacts"
            rm -rf "$PROJECT_ROOT/infra/tfplan"
            rm -rf "$PROJECT_ROOT/infra/.terraform"
            rm -rf "$PROJECT_ROOT/build"
            rm -rf "$PROJECT_ROOT/logs"
            success "Cleanup completed!"
            ;;
        "destroy")
            log "💥 Destroying infrastructure"
            read -p "Are you sure you want to destroy all resources? (yes/no): " confirm
            if [ "$confirm" = "yes" ]; then
                cd "$PROJECT_ROOT/infra"
                run_terraform "destroy" "Destroying infrastructure"
                success "Infrastructure destroyed!"
            else
                log "Destruction cancelled"
            fi
            ;;
        "status"|"output")
            log "📊 Getting deployment status"
            cd "$PROJECT_ROOT/infra"
            terraform output
            ;;
        "all"|*)
            log "🚀 Full deployment (infrastructure + backend + frontend)"
            
            # Infrastructure
            handle_existing_resources
            run_terraform "apply" "Applying infrastructure changes"
            
            # Wait a moment for resources to be ready
            log "⏳ Waiting for resources to be ready..."
            sleep 10
            
            # Backend
            deploy_functions
            
            # Frontend
            deploy_frontend
            
            success "🎉 Full deployment completed successfully!"
            
            # Show outputs
            log "📊 Deployment outputs:"
            cd "$PROJECT_ROOT/infra"
            terraform output
            ;;
    esac
}

# Show usage if help is requested
if [ "$1" = "help" ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  all        - Full deployment (default)"
    echo "  infra      - Deploy infrastructure only"
    echo "  functions  - Deploy backend functions only"
    echo "  frontend   - Deploy frontend only"
    echo "  status     - Show deployment status"
    echo "  clean      - Clean deployment artifacts"
    echo "  destroy    - Destroy all infrastructure"
    echo "  help       - Show this help message"
    echo ""
    echo "Environment:"
    echo "  Configure .env.local with your project settings"
    echo "  Ensure GOOGLE_APPLICATION_CREDENTIALS is set"
    exit 0
fi

# Trap to ensure we always return to original directory
trap 'cd "$PROJECT_ROOT"' EXIT

# Run main function with all arguments
main "$@"
