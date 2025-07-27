# Raseed Architecture

## C4 Diagram & Components

**High-level components:**
- **Flutter Web App**: Upload UI, real‑time receipt list, Chat UI, Wallet add‐button.
- **Receipt Orchestrator (Cloud Function #1)**: Event‑driven ADK SequentialAgent.
- **Chat Assistant (Cloud Function #2)**: HTTP ADK LlmAgent + tools.
- **Vertex AI services**: Vision OCR, Translation, Speech APIs, Gemini 2.5 Flash LLM, Gem‑Embedding‑01, Matching Engine.
- **Firebase**: Auth, Firestore, Storage bucket proxy.
- **Google Wallet API**: Generic passes.
- **Terraform‑managed GCP infra**: IAM, Monitoring, Budget, Secret Manager.

## End‑to‑end Data Flow

```
User → Flutter upload → Firebase Storage(receipts/userId/file)
 → GCS event → Receipt Orchestrator
     1. OCR (Vision)
     2. Translate (if !en)
     3. Embed (Gemini Embeddings) → Matching Engine
     4. Firestore doc{status:processing}
     5. Wallet pass JSON → Wallet API → JWT
     6. Firestore doc{status:completed,wallet_jwt}
 ← Firestore listener ← Flutter UI shows “Add to Wallet”

User → Chat UI (/api/chat or /api/voice)
 → Chat Assistant
     a. STT (if voice)
     b. Receipt‑Retrieval tool (vector + metadata)
     c. Optional Google Search tool
     d. Gemini Flash 2.5 reasoning
     e. Optional Wallet pass creation (shopping list etc.)
 ← Answer (+ TTS audio, + wallet_jwt) ← Flutter UI
```

## Component List
- **Flutter Web/Mobile**: Responsive, real-time, wallet integration
- **Cloud Functions**: Orchestrator (event), Chat (HTTP)
- **Vertex AI**: Vision, Translation, Embeddings, Matching Engine
- **Firestore**: User/receipt partitioned
- **Storage**: Per-user bucket folders
- **Wallet API**: Pass creation
- **Terraform**: Modular, environment-based
- **Monitoring**: Log-based metrics, alerts

See [infra-design.md](infra-design.md), [backend-design.md](backend-design.md), [frontend-design.md](frontend-design.md) for details.
