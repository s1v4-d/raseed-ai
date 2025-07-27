# Raseed Data Flow

## End-to-End Flow

1. **User uploads receipt** via Flutter app (web/mobile) → Firebase Storage at `receipts/{uid}/{filename}`
2. **GCS event** triggers Receipt Orchestrator (Cloud Function)
    - OCR (Vision API)
    - Translate (if not English)
    - Embed (Gemini Embeddings) → Matching Engine
    - Firestore doc `{status:processing}`
    - Wallet pass JSON → Wallet API → JWT
    - Firestore doc `{status:completed, wallet_jwt}`
3. **Flutter UI** listens to Firestore for status, shows “Add to Wallet” when ready
4. **User chats** via UI (text/voice) → Chat Assistant (Cloud Function)
    - STT (if voice)
    - Receipt-Retrieval tool (vector + metadata)
    - Google Search tool (optional)
    - Gemini Flash 2.5 LLM
    - Wallet pass creation (optional)
5. **Answer** (+ TTS audio, + wallet_jwt) returned to UI

## Data Partitioning
- **Storage**: `receipts/{uid}/...`
- **Firestore**: `users/{uid}/receipts/{receiptId}`
- **Matching Engine**: receiptId + uid metadata
- **Security**: All access gated by Firebase Auth (ID token)

## Security
- Firestore/Storage rules enforce `request.auth.uid == userId`
- App Check can be enabled for extra protection

See [backend-design.md](backend-design.md) and [frontend-design.md](frontend-design.md) for more.
