# Raseed - AI-Powered Receipt Manager for Google Wallet

An AI-powered personal assistant that acts as a comprehensive receipt manager and financial advisor for everyday users. Built with Google Cloud technologies, this project enables users to digitize receipts, track expenses, and gain valuable insights into their spending habits through Google Wallet integration.

## 🌟 Features

- **Multimodal Receipt Processing**: Upload photos, videos, or live streams of receipts in any language
- **AI-Powered Analysis**: Uses Gemini models to extract items, values, taxes, and fees
- **Google Wallet Integration**: Creates and manages passes for receipts and insights
- **Natural Language Queries**: Ask questions about spending in your local language
- **Smart Financial Insights**: AI-generated spending analysis and savings suggestions
- **Cross-Platform Frontend**: Flutter web application with Firebase hosting

## 🏗️ Architecture

- **Backend**: Python Cloud Functions with Vertex AI integration
- **Frontend**: Flutter web application
- **Infrastructure**: Google Cloud Platform with Terraform
- **Database**: Firestore for data storage
- **AI Services**: Vertex AI, Gemini models, Vision API, Translation API
- **Authentication**: Firebase Auth
- **Storage**: Google Cloud Storage for receipts and ML models

## 🚀 Quick Setup Guide

### Prerequisites

- **Google Cloud Project** with billing enabled
- **Service Account Key** with owner permission
- **Local Development Environment** (Linux/macOS recommended)

### Step 1: Environment Setup

1. **Clone and Extract Project**
   ```bash
   # Already completed if you're reading this
   cd /workspaces/raseed-ai
   ```

2. **Install Google Cloud CLI**
   ```bash
   # Install gcloud CLI locally
   ./gcli/gcloud.sh --version  # Verify installation
   ```

3. **Configure Authentication**
   ```bash
   # Authenticate with your service account
   ./gcli/gcloud.sh auth activate-service-account --key-file=infra/secrets/raseed-ai.json
   ./gcli/gcloud.sh config set project "project id"
   ```

### Step 2: Environment Configuration

1. **Update Environment Variables**
   - add terraform.tfvars at infra/

2. **Verify Configuration Files**
   ```bash
   # Check terraform configuration
   cat infra/terraform.tfvars
   ```

### Step 3: Deploy Infrastructure and Application

**One-Command Deployment:**
```bash
./scripts/deploy_local.sh
```
i/gcloud.sh firebase hosting sites list
   ```

3. **Test Application**
   - Frontend will be deployed to Firebase Hosting
   - Access URL will be displayed after deployment
   - Test receipt upload and chat functionality

## 🔧 Development Commands

### Infrastructure Management
```bash
# View terraform outputs
cd infra && terraform output

# Check resource status
./scripts/discover_resources.sh raseed-ai-467202

# Emergency cleanup (if needed)
./scripts/emergency_vertex_cleanup.sh raseed-ai-467202 us-central1
```

### Application Development
```bash
# Run tests
./scripts/run_tests.sh

# Build frontend locally
cd frontend && flutter build web

# Check logs
./gcli/gcloud.sh functions logs read receipt-orchestrator --region=us-central1
```

### Environment Management
```bash
# Set up local development environment
source ./scripts/setup_local_env.sh

# Check authentication status
./gcli/gcloud.sh auth list
```

## 📁 Project Structure

```
raseed-ai/
├── backend/                    # Python Cloud Functions
│   ├── chat_assistant/        # AI chat service
│   └── receipt_orchestrator/  # Receipt processing
├── frontend/                  # Flutter web application
├── infra/                     # Terraform infrastructure
│   ├── modules/              # Reusable Terraform modules
│   └── secrets/              # Service account keys
├── scripts/                   # Deployment and utility scripts
├── docs/                      # Documentation
├── firebase/                  # Firebase configuration
└── gcli/                      # Local Google Cloud CLI
```

## 🎯 Key Configuration Files

- **`infra/terraform.tfvars`**: infrastructure configuration
- **`.env.local`**: Local development environment variables  
- **`infra/secrets/raseed-ai.json`**: Service account authentication
- **`firebase/firebase.json`**: Firebase project configuration
- **`scripts/deploy_local.sh`**: Main deployment script

## 🔐 Security Notes

- Service account key is stored in `infra/secrets/raseed-ai.json`
- All environment files are configured with proper project ID
- Sensitive files are excluded via `.gitignore`
- Use least-privilege IAM roles for production

## 🐛 Troubleshooting

### Common Issues

1. **gcloud command not found**: Use `./gcli/gcloud.sh` instead of `gcloud`
2. **Authentication errors**: Verify service account key path and permissions
3. **Resource conflicts**: Run `./scripts/check_and_import_resources.sh` to handle existing resources
4. **Terraform errors**: Check `logs/terraform.log` for detailed error information
5. **Vertex AI Index takes too long for creation**: The index is high dimensional and would take too long to create

### Vertex AI Index Optimization

The project uses an optimized Vertex AI configuration for faster deployment:
- **Small dimensions (2D)** for initial setup - can be expanded later via streaming updates
- **Brute force algorithm** for simpler, faster initialization  
- **COSINE_DISTANCE** for efficient similarity calculations
- **Public endpoint** for easier initial testing
- **Single replica** to minimize startup time

You can scale up the index later by:
1. Using streaming updates to add higher-dimensional embeddings
2. Switching to tree-AH algorithm for larger datasets
3. Increasing replica count for production loads

### Support Commands
```bash
# Check current configuration
./gcli/gcloud.sh config list

# Verify project access
./gcli/gcloud.sh projects describe 'project id'

# Check API enablement
./gcli/gcloud.sh services list --enabled
```

## 📖 Next Steps

1. **Deploy the application** using `./scripts/deploy_local.sh`
2. **Configure Google Wallet API** access in the Google Pay & Wallet Console
3. **Test receipt upload** functionality
4. **Customize AI prompts** and responses in the backend code
5. **Set up monitoring** and alerting for production use


## 🤝 Contributing

This project uses Google Cloud technologies and follows infrastructure-as-code principles. All changes should be made through Terraform configurations and deployed via the provided scripts.

---

**Project Raseed** - Transforming receipt management with AI and Google Wallet integration.

**TL;DR;**
- Add "GCP_Project_ID" and "GCP_SA_KEY" secrets in 'production' env in github actions.
- Everytime you push changes to main, it would deploy the application onto GCP