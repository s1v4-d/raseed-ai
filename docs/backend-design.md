# Backend Design

## Python ADK Microservices
- **receipt_orchestrator/**: Event-driven, sequential agent pipeline
- **chat_assistant/**: HTTP-triggered, LLM agent with tools
- **shared/**: Wallet helper, common utils

## SequentialAgent Pipeline
1. Ingest file (GCS event)
2. OCR (Vision API)
3. Translate (if needed)
4. Embed (Gemini Embeddings)
5. Persist (Firestore)
6. Wallet pass (JWT)

## LlmAgent (Chat)
- Gemini 2.5 Flash LLM
- Tools: Receipt search, Google Search, calculator, translation, STT/TTS
- Verifies Firebase ID token for every request

## Data Partitioning
- All data keyed by user ID (uid)
- Firestore: `users/{uid}/receipts/{receiptId}`
- Storage: `receipts/{uid}/...`
- Matching Engine: receiptId + uid metadata

## Security
- Firebase Auth required for all access
- Firestore/Storage rules enforce per-user access

## Dependencies
- Python requirements locked per function
- See `backend/requirements.txt`

See [infra-design.md](infra-design.md) for deployment details.
