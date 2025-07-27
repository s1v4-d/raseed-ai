# Firebase Authentication Setup (Post-Token Deprecation)

## Overview

This project has been updated to remove the deprecated `FIREBASE_TOKEN` authentication method and now uses **Google Cloud Service Account** authentication with **Application Default Credentials (ADC)**.

## Authentication Methods

### 1. GitHub Actions CI/CD (Recommended)
- Uses `google-github-actions/auth@v2` with service account key
- Firebase CLI automatically uses ADC
- No tokens needed

### 2. Local Development
```bash
# One-time setup
./scripts/setup_dev.sh

# This will:
# - Install Firebase CLI if needed  
# - Setup Application Default Credentials
# - Configure project settings
```

### 3. Manual Setup (Alternative)
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Setup ADC
gcloud auth application-default login

# Use your project
firebase use your-project-id
```

## Key Changes

### ❌ Old (Deprecated)
```bash
firebase deploy --only hosting --token $FIREBASE_TOKEN
```

### ✅ New (Current)
```bash
# Firebase CLI automatically uses ADC
firebase deploy --only hosting
```

## Service Account Permissions

Your GCP service account needs these roles:
- `roles/firebase.admin` (or specific Firebase roles)
- `roles/cloudfunctions.admin`
- `roles/storage.admin`
- `roles/servicemanagement.serviceController`

## Terraform Integration

Firebase resources are now fully managed by Terraform:
- Firebase project setup
- Hosting configuration
- Function rewrites
- All done without Firebase CLI tokens

## Troubleshooting

### Error: "Authentication Required"
```bash
# Re-authenticate
gcloud auth application-default login
firebase login --reauth
```

### Error: "Project not found"
```bash
# Ensure project is set
gcloud config set project YOUR_PROJECT_ID
firebase use YOUR_PROJECT_ID
```

### Error: "Permission denied"
Check that your service account has the required Firebase roles listed above.

## Migration Notes

If you're migrating from the old token-based auth:
1. Remove `FIREBASE_TOKEN` from your environment variables
2. Update CI/CD workflows to use the new flow
3. Run `./scripts/setup_dev.sh` for local development
4. Re-run terraform to set up Firebase resources

## References

- [Firebase CLI Authentication](https://firebase.google.com/docs/cli#authentication)
- [Google Cloud ADC](https://cloud.google.com/docs/authentication/application-default-credentials)
- [Firebase Tools GitHub](https://github.com/firebase/firebase-tools)
