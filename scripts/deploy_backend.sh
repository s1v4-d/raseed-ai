#!/usr/bin/env bash
set -e
REGION=${REGION:-us-central1}
RECEIPT_BUCKET=${RECEIPT_BUCKET:?}
FUNCTIONS_SA=${FUNCTIONS_SA:?}

# Check if PROJECT_ID is set
PROJECT_ID=${PROJECT_ID:?}

echo "🚀  Deploying receipt‑orchestrator"
gcloud functions deploy receipt-orchestrator \
  --gen2 --runtime python312 --entry-point on_gcs_finalise \
  --trigger-bucket "$RECEIPT_BUCKET" \
  --region "$REGION" \
  --source backend/receipt_orchestrator \
  --service-account "$FUNCTIONS_SA" \
  --memory 1Gi \
  --timeout 540s

echo "💬  Deploying chat‑assistant"
gcloud functions deploy chat-assistant \
  --gen2 --runtime python312 --entry-point chat \
  --trigger-http \
  --region "$REGION" \
  --source backend/chat_assistant \
  --no-allow-unauthenticated \
  --service-account "$FUNCTIONS_SA" \
  --memory 1Gi \
  --timeout 540s
